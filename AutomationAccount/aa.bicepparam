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
