#Requires -Module Az.Accounts, Az.Resources, Az.Network, Az.ManagementGroups, Az.Compute

param(
    [Parameter(Mandatory = $false)]
    [string]$ManagementGroupName = "ManagedWorkloads"
)

# Login to Azure using Managed Identity
try {
    Write-Output "Connecting to Azure with Managed Identity..."
    Connect-AzAccount -Identity | Out-Null
    Write-Output "Successfully connected to Azure"
} catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    exit 1
}

# Function to create NSG with only built-in rules
function New-DefaultNSG {
    param(
        [string]$NSGName,
        [string]$ResourceGroupName,
        [string]$Location
    )
    
    Write-Output "Creating NSG: $NSGName in Resource Group: $ResourceGroupName"
    
    try {
        # Create NSG with no custom security rules (only built-in rules will be present)
        $nsg = New-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $Location
        
        # Ensure we return a single object, not an array
        if ($nsg -is [array]) {
            return $nsg[0]
        }
        return $nsg
        
    } catch {
        Write-Error "Failed to create NSG $NSGName in resource group $ResourceGroupName`: $($_.Exception.Message)"
        throw
    }
}

# Function to get VM name from VM resource ID
function Get-VMNameFromResourceId {
    param(
        [string]$ResourceId
    )
    
    if ($ResourceId) {
        $vmName = $ResourceId.Split('/')[-1]
        return $vmName
    }
    return $null
}

# Function to process NICs in a subscription
function Process-SubscriptionNICs {
    param(
        [string]$SubscriptionId,
        [string]$SubscriptionName
    )
    
    try {
        # Set context silently
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        
        # Get all NICs that are attached to VMs
        $nics = Get-AzNetworkInterface | Where-Object { 
            $_.VirtualMachine -ne $null 
        }
        
        Write-Output "[$SubscriptionName] Found $($nics.Count) NICs attached to VMs"
        
        if ($nics.Count -eq 0) {
            return
        }
        
        foreach ($nic in $nics) {
            try {
                $nicName = $nic.Name
                $resourceGroupName = $nic.ResourceGroupName
                $location = $nic.Location
                
                # Get VM name from the VM resource ID
                $vmName = Get-VMNameFromResourceId -ResourceId $nic.VirtualMachine.Id
                
                if (-not $vmName) {
                    Write-Warning "[$SubscriptionName] Could not determine VM name for NIC $nicName. Skipping..."
                    continue
                }
                
                $nsgName = "$vmName-NSG"
                
                # Check if NIC already has NSG attached
                if ($nic.NetworkSecurityGroup -ne $null) {
                    Write-Output "[$SubscriptionName] NIC $nicName (VM: $vmName) already has NSG attached. Skipping..."
                    continue
                }
                
                Write-Output "[$SubscriptionName] Processing NIC: $nicName (VM: $vmName)"
                
                # Check if NSG with name [VMName-NSG] exists in the same resource group
                $existingNSG = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                
                if ($existingNSG) {
                    Write-Output "[$SubscriptionName] NSG $nsgName already exists. Attaching to NIC..."
                    $nsg = $existingNSG
                } else {
                    Write-Output "[$SubscriptionName] Creating new NSG: $nsgName"
                    $nsg = New-DefaultNSG -NSGName $nsgName -ResourceGroupName $resourceGroupName -Location $location
                }
                
                # Validate NSG object before attachment
                if ($nsg -and $nsg.Id) {
                    # Refresh the NIC object to get the latest state
                    $refreshedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName
                    
                    # Attach NSG to NIC using the ID reference
                    $refreshedNic.NetworkSecurityGroup = @{
                        Id = $nsg.Id
                    }
                    
                    $result = Set-AzNetworkInterface -NetworkInterface $refreshedNic
                    
                    if ($result.ProvisioningState -eq "Succeeded") {
                        Write-Output "[$SubscriptionName] Successfully attached NSG $nsgName to NIC $nicName"
                    } else {
                        Write-Warning "[$SubscriptionName] NSG attachment may have failed. ProvisioningState: $($result.ProvisioningState)"
                    }
                } else {
                    Write-Error "[$SubscriptionName] Failed to create or retrieve NSG $nsgName"
                }
                
            } catch {
                Write-Error "[$SubscriptionName] Failed to process NIC $nicName`: $($_.Exception.Message)"
            }
        }
        
    } catch {
        Write-Error "[$SubscriptionName] Failed to process subscription: $($_.Exception.Message)"
    }
}

# Main execution
try {
    # Get all subscriptions under the specified management group
    Write-Output "Getting subscriptions under Management Group: $ManagementGroupName"
    
    # Using -GroupName parameter with the renamed variable
    $managementGroup = Get-AzManagementGroup -GroupName $ManagementGroupName -Expand -Recurse
    $subscriptions = @()
    
    Write-Output "Management Group: $($managementGroup.DisplayName) ($($managementGroup.Children.Count) subscriptions)"
    
    # Extract subscriptions from management group hierarchy
    function Get-SubscriptionsFromMG {
        param($MG)
        
        if ($MG.Children) {
            foreach ($child in $MG.Children) {
                if ($child.Type -eq "Microsoft.Management/managementGroups") {
                    # Recursively process nested management groups
                    try {
                        $childMG = Get-AzManagementGroup -GroupName $child.Name -Expand -Recurse
                        Get-SubscriptionsFromMG -MG $childMG
                    } catch {
                        Write-Warning "Failed to get child management group $($child.Name): $($_.Exception.Message)"
                    }
                } elseif ($child.Type -eq "/subscriptions") {
                    # Add subscription to the list
                    $script:subscriptions += @{
                        Id = $child.Name
                        Name = $child.DisplayName
                    }
                    Write-Output "Found subscription: $($child.DisplayName)"
                }
            }
        }
    }
    
    Get-SubscriptionsFromMG -MG $managementGroup
    
    if ($subscriptions.Count -eq 0) {
        Write-Warning "No subscriptions found in management group hierarchy."
        exit 0
    }
    
    Write-Output "Processing $($subscriptions.Count) subscriptions for NSG attachment..."
    Write-Output ""
    
    # Process subscriptions sequentially
    foreach ($subscription in $subscriptions) {
        try {
            Process-SubscriptionNICs -SubscriptionId $subscription.Id -SubscriptionName $subscription.Name
        } catch {
            Write-Error "Failed to process subscription $($subscription.Name): $($_.Exception.Message)"
        }
    }
    
    Write-Output ""
    Write-Output "NSG attachment process completed for all subscriptions"
    
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}