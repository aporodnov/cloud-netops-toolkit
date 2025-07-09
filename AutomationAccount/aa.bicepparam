using 'aa.bicep'

param resourceGroupName = 'NetOpsToolkit-RG'
param location = 'canadacentral'

param tags = {
  Environment: 'Production'
  ApplicationName: 'NetOpsToolkit'
}

param AAName = 'NetOpsToolkit-AA'
