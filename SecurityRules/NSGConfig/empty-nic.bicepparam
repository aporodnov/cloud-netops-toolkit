using '../modules/nsg.bicep'

param RGName = 'app456-rg'

param NSGName = 'empty-nic-Nsg'

param securityRules = [
  {
    name: 'deny-hop-outbound'
    properties: {
      direction: 'Outbound'
      access: 'Deny'
      priority: 200
      protocol: 'Tcp'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRanges: [
        '22'
        '3389'
      ]
    }
  }
]

