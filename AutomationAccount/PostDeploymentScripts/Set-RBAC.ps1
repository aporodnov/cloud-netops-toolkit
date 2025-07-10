#This is a post deployment configuration script to setup permissions for Automation Account

#For the runbook to work, we need to assigned system-managed identity from AA the Contributor permissions 
#for AA account itself and on the scope of management groups where all subscriptions will be located

Connect-AzAccount

# Get Automation Account system-managed identity
$aa = Get-AzAutomationAccount -ResourceGroupName "NetOpsToolkit-RG" -Name "NetOpsToolkit-AA"
$SPNobjectID = $aa.Identity.PrincipalId

#Contributor RoleDefinition ID is b24988ac-6180-42a0-ab88-20f7382dd24c
$RoleDefinitionId = "b24988ac-6180-42a0-ab88-20f7382dd24c"

#Scope for AA RG
$ScopeAARG = "/subscriptions/ccf12f80-8b9f-4db9-a5d2-0e8e6b7785a9/resourceGroups/NetOpsToolkit-RG"
#Scope for ManagementGroup
$ScopeMgmtGroup = "/providers/Microsoft.Management/managementGroups/ManagedWorkloads"

# Assign Contributor role at Resource Group scope (with Automation Account)
New-AzRoleAssignment -ObjectId $SPNobjectID -RoleDefinitionId $RoleDefinitionId -Scope $ScopeAARG

# Assign Contributor role at  Management Group scope
New-AzRoleAssignment -ObjectId $SPNobjectID -RoleDefinitionId $RoleDefinitionId -Scope $ScopeMgmtGroup

Write-Output "RBAC permissions set successfully for $SPNobjectID"