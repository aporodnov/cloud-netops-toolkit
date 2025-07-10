using '../modules/nsg.bicep'

param RGName = 'CopilotApp'

param NSGName = 'CopilotProc01-NSG'

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

