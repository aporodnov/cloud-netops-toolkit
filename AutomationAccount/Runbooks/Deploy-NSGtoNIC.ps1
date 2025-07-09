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
    
    # Create NSG with no custom security rules (only built-in rules will be present)
    $nsg = New-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $Location
    
    return $nsg
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
                
                # Attach NSG to NIC
                Write-Output "Attaching NSG $nsgName to NIC $nicName"
                $nic.NetworkSecurityGroup = $nsg
                Set-AzNetworkInterface -NetworkInterface $nic
                
                Write-Output "Successfully attached NSG $nsgName to NIC $nicName"
                
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
    
    # Extract subscriptions from management group hierarchy
    function Get-SubscriptionsFromMG {
        param($MG)
        
        if ($MG.Children) {
            foreach ($child in $MG.Children) {
                if ($child.Type -eq "/providers/Microsoft.Management/managementGroups") {
                    Get-SubscriptionsFromMG -MG $child
                } elseif ($child.Type -eq "/providers/Microsoft.Management/managementGroups/subscriptions") {
                    $script:subscriptions += $child.Name
                }
            }
        }
    }
    
    Get-SubscriptionsFromMG -MG $managementGroup
    
    Write-Output "Found $($subscriptions.Count) subscriptions in Management Group $ManagementGroupName"
    
    # Process subscriptions in parallel
    $subscriptions | ForEach-Object -Parallel {
        # Import required modules in parallel runspace
        Import-Module Az.Network, Az.Resources
        
        # Redefine functions in parallel runspace
        function New-DefaultNSG {
            param(
                [string]$NSGName,
                [string]$ResourceGroupName,
                [string]$Location
            )
            
            Write-Output "Creating NSG: $NSGName in Resource Group: $ResourceGroupName with built-in rules only"
            
            # Create NSG with no custom security rules (only built-in rules will be present)
            $nsg = New-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $Location
            
            return $nsg
        }
        
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
        
        # Process subscription
        try {
            Write-Output "Processing subscription: $_"
            Set-AzContext -SubscriptionId $_
            
            $nics = Get-AzNetworkInterface | Where-Object { 
                $_.VirtualMachine -ne $null 
            }
            
            Write-Output "Found $($nics.Count) NICs attached to VMs in subscription $_"
            
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
                    
                    if ($nic.NetworkSecurityGroup -ne $null) {
                        Write-Output "NIC $nicName already has NSG attached. Skipping..."
                        continue
                    }
                    
                    $existingNSG = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                    
                    if ($existingNSG) {
                        Write-Output "NSG $nsgName already exists. Attaching to NIC $nicName"
                        $nsg = $existingNSG
                    } else {
                        Write-Output "NSG $nsgName does not exist. Creating new NSG with built-in rules only..."
                        $nsg = New-DefaultNSG -NSGName $nsgName -ResourceGroupName $resourceGroupName -Location $location
                    }
                    
                    Write-Output "Attaching NSG $nsgName to NIC $nicName"
                    $nic.NetworkSecurityGroup = $nsg
                    Set-AzNetworkInterface -NetworkInterface $nic
                    
                    Write-Output "Successfully attached NSG $nsgName to NIC $nicName"
                    
                } catch {
                    Write-Error "Failed to process NIC $nicName`: $($_.Exception.Message)"
                }
            }
            
        } catch {
            Write-Error "Failed to process subscription $_ : $($_.Exception.Message)"
        }
    } -ThrottleLimit 5
    
    Write-Output "NSG attachment process completed for all subscriptions"
    
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}