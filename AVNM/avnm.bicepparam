using 'avnm.bicep'

param resourceGroupName = 'AVNM-RG'
param location = 'canadacentral'

param tags = {
  Environment: 'Production'
  ApplicationName: 'AVNM'
}

param networkManagerName = 'NetworkManager-01'
param networkManagerSubscriptionScopes = [

]
// param networkManagerNetworkGroups = {
  
// }
// param networkManagerSecurityAdminConfigurations = {

// }

