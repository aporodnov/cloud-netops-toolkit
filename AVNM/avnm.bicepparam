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
]
// param networkManagerNetworkGroups = {
  
// }
// param networkManagerSecurityAdminConfigurations = {

// }

