using 'aa.bicep'

param resourceGroupName = 'NetOpsToolkit-RG'
param location = 'canadacentral'

param tags = {
  Environment: 'Production'
  ApplicationName: 'NetOpsToolkit'
}

param AAName = 'NetOpsToolkit-AA'

param automationAccountRunbooks = [
  {
    name: 'Deploy-NSGtoNIC'
    type: 'PowerShell'
    uri: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.automation/101-automation/scripts/AzureAutomationTutorial.ps1'
    version: '1.0.0.0'
  }
]

param automationAccountSchedules = [
  {
    advancedSchedule: {}
    expiryTime: '9999-12-31T13:00'
    frequency: 'Hour'
    interval: 1
    name: 'HourlySchedule'
    startTime: ''
    timeZone: 'America/Vancouver'
  }
]

param automationAccountJobSchedules = [
  {
    runbookName: 'Deploy-NSGtoNIC'
    scheduleName: 'HourlySchedule'
  }
]
