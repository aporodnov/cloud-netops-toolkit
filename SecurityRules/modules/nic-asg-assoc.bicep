@description('The resource ID of the Application Security Group to associate')
param asgId string

@description('Array of NIC resource IDs to associate with the ASG')
param nicIds array

@batchSize(1)
resource nicAssoc 'Microsoft.Network/networkInterfaces@2023-05-01' = [for nicId in nicIds: {
  name: last(split(nicId, '/'))
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          applicationSecurityGroups: [
            {
              id: asgId
            }
          ]
        }
      }
    ]
  }
}]
