@description('The resource ID of the Application Security Group to associate')
param asgId string

@description('Array of NIC resource IDs to associate with the ASG')
param nicIds array

@description('Location for the NICs')
param location string

param vnetId string
param subnetName string

@batchSize(1)
resource nicAssoc 'Microsoft.Network/networkInterfaces@2023-05-01' = [for nicId in nicIds: {
  name: last(split(nicId, '/'))
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: '${vnetId}/subnets/${subnetName}' }
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
