@description('Name of the Application Security Group')
param asgName string

@description('Location for the ASG')
param location string

resource asg 'Microsoft.Network/applicationSecurityGroups@2024-07-01' = {
  name: asgName
  location: location
}

output asgId string = asg.id
