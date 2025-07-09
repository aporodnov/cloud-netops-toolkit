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
// Setup virtual network that will be in scope for security admin rules (VNETs must reside within the SubscriptionScope)
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
// Setup Security Admin Config
param subscriptionId = 'ccf12f80-8b9f-4db9-a5d2-0e8e6b7785a9'
param networkManagerSecurityAdminConfigurations = [
  {
    name: 'CentralSecurityAdminRules'
    description: 'override NIC NSG with this rule collection on managedWorkloads vnets'
    applyOnNetworkIntentPolicyBasedServices: [
      'None'
    ]
    ruleCollections: [
      {
        name: 'CentralRuleCollection'
        appliesToGroups: [
          {
            networkGroupResourceId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Network/networkManagers/${networkManagerName}/networkGroups/${networkManagerNetworkGroups[0].name}'
          }
        ]
        rules: [
            {
              access: 'Allow'
              destinationPortRanges: [
                '442-445'
                '80'
              ]
              destinations: [
                {
                  addressPrefix: '192.168.20.20'
                  addressPrefixType: 'IPPrefix'
                }
              ]
              direction: 'Inbound'
              name: 'test-inbound-allow-rule-3'
              priority: 250
              protocol: 'Tcp'
            }
            {
              access: 'AlwaysAllow'
              description: 'test-outbound-deny-rule-2-description'
              direction: 'Outbound'
              name: 'test-outbound-deny-rule-2'
              priority: 200
              protocol: 'Tcp'
              sourcePortRanges: [
                '442-445'
                '80'
              ]
              sources: [
                {
                  addressPrefix: 'AppService.WestEurope'
                  addressPrefixType: 'ServiceTag'
                }
              ]
            }
        ]
      }
    ]
  }
]
