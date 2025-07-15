using '../modules/asgDeploy.bicep'
//the deployment will only work if ALL NICs are in the same resource group!!!

param RGName = 'app456-rg'
param asgName = 'Web01'
param location = 'canadacentral'

param vnetId = '/subscriptions/a31fc76b-e874-4a57-98b2-3d312d195025/resourceGroups/avnm-test-rg/providers/Microsoft.Network/virtualNetworks/avnmtestSpoke1'
param subnetName = 'default'

param nicIds = [
  '/subscriptions/a31fc76b-e874-4a57-98b2-3d312d195025/resourceGroups/app456-rg/providers/Microsoft.Network/networkInterfaces/app456510'
  // '/subscriptions/a31fc76b-e874-4a57-98b2-3d312d195025/resourceGroups/app456-rg/providers/Microsoft.Network/networkInterfaces/empty-nic'
]
