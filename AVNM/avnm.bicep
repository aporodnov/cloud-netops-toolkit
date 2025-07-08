targetScope = 'subscription'

@description('Name of the resource group to create')
param resourceGroupName string

@description('Location for the resource group')
param location string

@description('Location for the resource group')
param tags object

resource AVNM_RG 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

param networkManagerName string
param networkManagerSubscriptionScopes array
param networkManagerNetworkGroups array
// param networkManagerSecurityAdminConfigurations object
module networkManager 'br/public:avm/res/network/network-manager:0.5.2' = {
  name: 'AVNM_Instance_Deployment'
  scope: AVNM_RG
  params: {
    name: networkManagerName
    location: location
    networkManagerScopes: {
      subscriptions: networkManagerSubscriptionScopes
    }
    networkManagerScopeAccesses: [
      'SecurityAdmin'
    ]
    networkGroups: networkManagerNetworkGroups
    // securityAdminConfigurations: [
    //   networkManagerSecurityAdminConfigurations
    // ]
  }
}
