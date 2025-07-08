using 'avnm.bicep'

param resourceGroupName = 'AVNM-RG'
param location = 'canadacentral'

param tags = {
  Environment: 'Production'
  ApplicationName: 'AVNM'
}

param networkManagerName = 'NetworkManager-01'
param networkManagerSubscriptionScopes = [
  '/subscriptions/a31fc76b-e874-4a57-98b2-3d312d195025'
  '/subscriptions/e6f19bf3-8bef-4939-95dc-b7b7092ea430'
]
param networkManagerNetworkGroups = [
  {
    name: 'ManagedWorkloads-SpokesNG'
    description: 'Network Group that include ManagedWorkloadVNETs'
    staticMembers: [
      {
        name: 'avnmtestSpoke1'
        resourceId: '/subscriptions/a31fc76b-e874-4a57-98b2-3d312d195025/resourceGroups/avnm-test-rg/providers/Microsoft.Network/virtualNetworks/avnmtestSpoke1'
      }
      {
        name: 'avnmtestSpoke2'
        resourceId: '/subscriptions/e6f19bf3-8bef-4939-95dc-b7b7092ea430/resourceGroups/avnmtest-rg/providers/Microsoft.Network/virtualNetworks/avnmtestSpoke2'
      }
    ]
  }
]
// param networkManagerSecurityAdminConfigurations = {

// }

