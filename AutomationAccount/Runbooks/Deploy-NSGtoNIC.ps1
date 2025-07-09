#Requires -Module Az.Accounts, Az.Resources, Az.Network, Az.ManagementGroups, Az.Compute

param(
    [Parameter(Mandatory = $false)]
    [string]$ManagementGroupName = "ManagedWorkloads"
)

# Login to Azure using Managed Identity
try {
    Write-Output "Connecting to Azure with Managed Identity..."
    Connect-AzAccount -Identity
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
    
    Write-Output "Creating NSG: $NSGName in Resource Group: $ResourceGroupName with built-in rules only"
    
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
        [string]$SubscriptionId
    )
    
    try {
        Write-Output "Processing subscription: $SubscriptionId"
        Set-AzContext -SubscriptionId $SubscriptionId
        
        # Get all NICs that are attached to VMs
        $nics = Get-AzNetworkInterface | Where-Object { 
            $_.VirtualMachine -ne $null 
        }
        
        Write-Output "Found $($nics.Count) NICs attached to VMs in subscription $SubscriptionId"
        
        foreach ($nic in $nics) {
            try {
                $nicName = $nic.Name
                $resourceGroupName = $nic.ResourceGroupName
                $location = $nic.Location
                
                # Get VM name from the VM resource ID
                $vmName = Get-VMNameFromResourceId -ResourceId $nic.VirtualMachine.Id
                
                if (-not $vmName) {
                    Write-Warning "Could not determine VM name for NIC $nicName. Skipping..."
                    continue
                }
                
                $nsgName = "$vmName-NSG"
                
                Write-Output "Processing NIC: $nicName (attached to VM: $vmName)"
                
                # Check if NIC already has NSG attached
                if ($nic.NetworkSecurityGroup -ne $null) {
                    Write-Output "NIC $nicName already has NSG attached. Skipping..."
                    continue
                }
                
                # Check if NSG with name [VMName-NSG] exists in the same resource group
                $existingNSG = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                
                if ($existingNSG) {
                    Write-Output "NSG $nsgName already exists. Attaching to NIC $nicName"
                    $nsg = $existingNSG
                } else {
                    Write-Output "NSG $nsgName does not exist. Creating new NSG with built-in rules only..."
                    $nsg = New-DefaultNSG -NSGName $nsgName -ResourceGroupName $resourceGroupName -Location $location
                }
                
                # Validate NSG object before attachment
                if ($nsg -and $nsg.Id) {
                    Write-Output "Attaching NSG $nsgName (ID: $($nsg.Id)) to NIC $nicName"
                    
                    # Refresh the NIC object to get the latest state
                    $refreshedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName
                    
                    # Attach NSG to NIC using the ID reference
                    $refreshedNic.NetworkSecurityGroup = @{
                        Id = $nsg.Id
                    }
                    
                    $result = Set-AzNetworkInterface -NetworkInterface $refreshedNic
                    
                    if ($result.ProvisioningState -eq "Succeeded") {
                        Write-Output "Successfully attached NSG $nsgName to NIC $nicName"
                    } else {
                        Write-Warning "NSG attachment may have failed. ProvisioningState: $($result.ProvisioningState)"
                    }
                } else {
                    Write-Error "Failed to create or retrieve NSG $nsgName - NSG object is null or missing ID"
                }
                
            } catch {
                Write-Error "Failed to process NIC $nicName`: $($_.Exception.Message)"
            }
        }
        
    } catch {
        Write-Error "Failed to process subscription $SubscriptionId`: $($_.Exception.Message)"
    }
}

# Main execution
try {
    # Get all subscriptions under the specified management group
    Write-Output "Getting subscriptions under Management Group: $ManagementGroupName"
    
    # Using -GroupName parameter with the renamed variable
    $managementGroup = Get-AzManagementGroup -GroupName $ManagementGroupName -Expand -Recurse
    $subscriptions = @()
    
    Write-Output "Management Group Details:"
    Write-Output "Name: $($managementGroup.Name)"
    Write-Output "DisplayName: $($managementGroup.DisplayName)"
    Write-Output "Children Count: $($managementGroup.Children.Count)"
    
    # Extract subscriptions from management group hierarchy
    function Get-SubscriptionsFromMG {
        param($MG)
        
        Write-Output "Processing Management Group: $($MG.Name) with $($MG.Children.Count) children"
        
        if ($MG.Children) {
            foreach ($child in $MG.Children) {
                Write-Output "Child Name: $($child.Name), Type: $($child.Type), DisplayName: $($child.DisplayName)"
                
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
                    $script:subscriptions += $child.Name
                    Write-Output "Added subscription: $($child.Name) ($($child.DisplayName))"
                }
            }
        } else {
            Write-Output "No children found in management group: $($MG.Name)"
        }
    }
    
    Get-SubscriptionsFromMG -MG $managementGroup
    
    Write-Output "Found $($subscriptions.Count) subscriptions in Management Group $ManagementGroupName"
    
    if ($subscriptions.Count -eq 0) {
        Write-Warning "No subscriptions found in management group hierarchy. Please verify the management group structure."
        exit 0
    }
    
    # List found subscriptions
    Write-Output "Subscriptions found:"
    foreach ($sub in $subscriptions) {
        Write-Output "  - $sub"
    }
    
    # Process subscriptions sequentially to avoid parameter set issues
    Write-Output "Processing subscriptions sequentially..."
    
    foreach ($subscriptionId in $subscriptions) {
        try {
            Write-Output "=" * 50
            Write-Output "Processing subscription: $subscriptionId"
            Process-SubscriptionNICs -SubscriptionId $subscriptionId
        } catch {
            Write-Error "Failed to process subscription $subscriptionId : $($_.Exception.Message)"
        }
    }
    
    Write-Output "NSG attachment process completed for all subscriptions"
    
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}