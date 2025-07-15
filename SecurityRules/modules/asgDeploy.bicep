targetScope = 'subscription'

@description('Resource group name where ASG and NICs will be deployed')
param RGName string

resource RG 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: RGName
}

@description('Name of the Application Security Group')
param asgName string

@description('Location for the ASG')
param location string

@description('Array of NIC resource IDs to add to the ASG')
param nicIds array

module asg 'asg.bicep' = {
  name: 'asgMain'
  scope: RG
  params: {
    asgName: asgName
    location: location
  }
}

// Only deploy NIC association if nicIds is not empty
module nicAsgAssoc 'nic-asg-assoc.bicep' = if (length(nicIds) > 0) {
  name: 'nicAsgAssoc'
  scope: RG
  params: {
    asgId: asg.outputs.asgId
    nicIds: nicIds
  }
}
