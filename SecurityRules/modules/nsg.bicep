targetScope = 'subscription'

param RGName string

resource RG 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: RGName
}

param NSGName string
param securityRules array

module NSG 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: 'Deploy-NSG'
  scope: RG
  params: {
    name: NSGName
    securityRules: securityRules
  }
}
