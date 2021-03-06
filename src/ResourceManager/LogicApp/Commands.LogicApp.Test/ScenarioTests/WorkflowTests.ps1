# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Test New-AzureRmLogicApp with physical file paths
Test New-AzureRmLogicApp using definition object and parameter file
Test New-AzureRmLogicApp using piped input
#>
function Test-CreateAndRemoveLogicApp
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname	
	$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowDefinition.json"
	$parameterFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowParameter.json"	

	#Create App Service Plan
	$planName = "StandardServicePlan"
	$Plan = TestSetup-CreateAppServicePlan $resourceGroup.ResourceGroupName $planName

	#Case1 : Using physical file
	$workflow = New-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -AppServicePlan $planName -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath
	
	Assert-NotNull $workflow	
	Assert-NotNull $workflow.Definition
	Assert-NotNull $workflow.Parameters
	Assert-AreEqual $workflowName $workflow.Name 
	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force

	#Case2 : Using definition object and parameter file
	$parameterFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowParameter.json"		
    $definition = [IO.File]::ReadAllText("$TestOutputRoot\Resources\TestSimpleWorkflowDefinition.json")

	$workflowName = getAssetname	
	$workflow = New-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Definition $definition -ParameterFilePath $parameterFilePath -AppServicePlan $planName
    
	Assert-NotNull $workflow	
	Assert-NotNull $workflow.Definition
	Assert-NotNull $workflow.Parameters
	Assert-AreEqual $workflowName $workflow.Name 
	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force

	#Case3 : Create using Piped input

	$workflowName = getAssetname	
	$workflow = $resourceGroup | New-AzureRmLogicApp -Name $workflowName -AppServicePlan $planName -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath    
	
	Assert-NotNull $workflow
	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force
}

<#
.SYNOPSIS
Test New-AzureRmLogicApp to create a workflow with a duplicate name.
#>
function Test-CreateLogicAppWithDuplicateName
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	
	$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowDefinition.json"
	$parameterFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowParameter.json"
	$resourceGroupName = $resourceGroup.ResourceGroupName

	#Create App Service Plan
	$planName = "StandardServicePlan"
	$Plan = TestSetup-CreateAppServicePlan $resourceGroup.ResourceGroupName $planName

	$workflow = $resourceGroup | New-AzureRmLogicApp -Name $workflowName -AppServicePlan $planName -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath
    
	Assert-NotNull $workflow
	try
	{
		$workflow = $resourceGroup | New-AzureRmLogicApp -Name $workflowName -AppServicePlan $planName -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath
	}
	catch
	{		
		Assert-AreEqual $_.Exception.Message "The Resource 'Microsoft.Logic/workflows/$WorkflowName' under resource group '$resourceGroupName' already exists."		
	}
	
	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force	
}

<#
.SYNOPSIS
Test New-AzureRmLogicApp with workflow object
#>
function Test-CreateLogicAppUsingInputfromWorkflowObject
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname	
	$newWorkflowName = getAssetname	
	$resourceGroupName = $resourceGroup.ResourceGroupName
	
	$planName = "StandardServicePlan"
	$Plan = TestSetup-CreateAppServicePlan $resourceGroup.ResourceGroupName $planName

	$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowDefinition.json"
	$parameterFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowParameter.json"

	$workflow = New-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -AppServicePlan $planName -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath 
	$workflow = New-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $newWorkflowName -AppServicePlan $planName -Definition $workflow.Definition -Parameters $workflow.Parameters
		    
	Assert-NotNull $workflow	
	Assert-NotNull $workflow.Definition
	Assert-NotNull $workflow.Parameters
	Assert-AreEqual $newWorkflowName $workflow.Name 
	Assert-AreEqual "Enabled" $workflow.State

	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Force	
}

<#
.SYNOPSIS
Test New-AzureRmLogicApp with Parameter as hash table
#>
function Test-CreateLogicAppUsingInputParameterAsHashTable
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname	
	$resourceGroupName = $resourceGroup.ResourceGroupName

	$planName = "StandardServicePlan"
	$Plan = TestSetup-CreateAppServicePlan $resourceGroup.ResourceGroupName $planName

	$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowDefinition.json"	
	$parameters = @{destinationUri="http://www.bing.com"}
		
	$workflow = New-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Parameters $parameters -AppServicePlan $planName
		    
	Assert-NotNull $workflow	
	Assert-NotNull $workflow.Parameters
	
	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force	
}

<#
.SYNOPSIS
Test New-AzureRmLogicApp with only definition
#>
function Test-CreateLogicAppUsingDefinitionWithTriggers
{		
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname	
	$resourceGroupName = $resourceGroup.ResourceGroupName		
	$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowTriggerDefinition.json"

	$planName = "StandardServicePlan"
	$Plan = TestSetup-CreateAppServicePlan $resourceGroup.ResourceGroupName $planName

	$workflow = New-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -AppServicePlan $planName
		    
	Assert-NotNull $workflow
	
	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Force			
}

<#
.SYNOPSIS
Test New-AzureRmLogicApp with only definition
Test Get-AzureRmLogicApp 
Test Get-AzureRmLogicApp for a non-existing logic app
#>
function Test-CreateAndGetLogicAppUsingDefinitionWithActions
{	
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname	
	$resourceGroupName = $resourceGroup.ResourceGroupName		
	$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowActionDefinition.json"
	$planName = "StandardServicePlan"
	$Plan = TestSetup-CreateAppServicePlan $resourceGroup.ResourceGroupName $planName
	
	#Case1: Create logic app without parameters
	$workflow1 = New-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -AppServicePlan $planName
	Assert-NotNull $workflow1	

	#Case1: Get logic app using get cmdlet
	$workflow2 = Get-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	Assert-NotNull $workflow2

	#Case1: Get non-existing logic app using get cmdlet
	try
	{
		Get-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name "InvalidWorkflow"
	}
	catch
	{		
		Assert-AreEqual $_.Exception.Message "The Resource 'Microsoft.Logic/workflows/InvalidWorkflow' under resource group '$resourceGroupName' was not found."		
	} 

	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Force		
}

<#
.SYNOPSIS
Test Remove-AzureRmLogicApp command to remove nonexisting workflow by name.
#>
function Test-RemoveNonExistingLogicApp
{
	$WorkflowName = "09e81ac4-848a-428d-82a6-7d61953e3940"
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName
			
	Remove-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $WorkflowName -Force
}

<#
.SYNOPSIS
Test Set-AzureRmLogicApp command to update workflow definition without parameters.
Test Set-AzureRmLogicApp command to update workflow definition and state to Disabled.
Test Set-AzureRmLogicApp command to update workflow state to Enabled.
Test Set-AzureRmLogicApp command to set logic app with null definition.
Test Set-AzureRmLogicApp command to set non-existing logic app.
#>
function Test-UpdateLogicApp
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname	
	$resourceGroupName = $resourceGroup.ResourceGroupName

	$planName = "StandardServicePlan"
	$Plan = TestSetup-CreateAppServicePlan $resourceGroup.ResourceGroupName $planName

	$simpleDefinitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowDefinition.json"
	$simpleParameterFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowParameter.json"
	$workflow = $resourceGroup | New-AzureRmLogicApp -Name $workflowName -AppServicePlan $planName -DefinitionFilePath $simpleDefinitionFilePath -ParameterFilePath $simpleParameterFilePath
	
	Assert-NotNull $workflow
					
	#Case1: Update definition with no parameters and disable
	$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowTriggerDefinition.json"

	$UpdatedWorkflow = Set-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -State "Disabled" -DefinitionFilePath $definitionFilePath -Parameters $null
	
	Assert-NotNull $UpdatedWorkflow
	Assert-AreEqual $UpdatedWorkflow.State "Disabled"

	#Case2: Update definition with parameters of logic app
	$UpdatedWorkflow = Set-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $simpleDefinitionFilePath -ParameterFilePath $simpleParameterFilePath

	Assert-NotNull $UpdatedWorkflow

	#Case3: Enable the logic app
	$UpdatedWorkflow = Set-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -State "Enabled"
	
	Assert-NotNull $UpdatedWorkflow
	Assert-AreEqual $UpdatedWorkflow.State "Enabled"

	#Case4: Test update command to set logic app with null definition
	try
	{
		$UpdatedWorkflow = Set-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Definition $null
	}
	catch
	{		
		Assert-AreEqual $_.Exception.Message "Definition content needs to be specified."		
	}

	#Case5: Update non-existing workflow

	try
	{
		$workflowName = "82D2D842-C312-445C-8A4D-E3EE9542436D"
		$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowTriggerDefinition.json"
		Set-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -AppServicePlan $planName -DefinitionFilePath $definitionFilePath
	}
	catch
	{		
		Assert-AreEqual $_.Exception.Message "The Resource 'Microsoft.Logic/workflows/$workflowName' under resource group '$resourceGroupName' was not found."		
	}
}

<#
.SYNOPSIS
Test New-AzureRmLogicApp to create logic app for non-existing service plan. Constraint validation.
#>
function Test-CreateLogicAppWithNonExistingAppServicePlan
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname		
	$resourceGroupName = $resourceGroup.ResourceGroupName	
	$definitionFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowDefinition.json"
	$parameterFilePath = "$TestOutputRoot\Resources\TestSimpleWorkflowParameter.json"
	$Plan = "B9F87338CAE4470F9116F3D685365748"
	try
	{
		$workflow = New-AzureRmLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName	-AppServicePlan $Plan -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath	
	}
	catch
	{		
		Assert-AreEqual $_.Exception.Message "The Resource 'Microsoft.Web/serverFarms/$Plan' under resource group '$resourceGroupName' was not found."
	} 			
}