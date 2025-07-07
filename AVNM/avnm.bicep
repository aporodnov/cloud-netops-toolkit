targetScope = 'subscription'

@description('Name of the resource group to create')
param resourceGroupName string

@description('Location for the resource group')
param location string

@description('Location for the resource group')
param tags object

module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'RG_Deployment'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}
