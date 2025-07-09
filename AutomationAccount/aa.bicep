targetScope = 'subscription'

@description('Name of the resource group to create')
param resourceGroupName string

@description('Location for the resource group')
param location string

@description('Location for the resource group')
param tags object

resource AA_RG 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

param AAName string

module automationAccount 'br/public:avm/res/automation/automation-account:0.15.0' = {
  name: 'Deploy_AutomationAccount'
  scope: AA_RG
  params: {
    name: AAName
  }
}
