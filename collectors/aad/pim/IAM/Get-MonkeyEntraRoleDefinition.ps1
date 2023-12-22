# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


function Get-MonkeyEntraRoleDefinition {
<#
        .SYNOPSIS
		Collector to get information about role definition from PIM

        .DESCRIPTION
		Collector to get information about role definition from PIM

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEntraRoleDefinition
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "aad0090";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEntraRoleDefinition";
			ApiType = "PIM";
			description = "Collector to get information about role definition from PIM";
			Group = @(
				"EntraID"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"aad_pim_roleDefinition",
				"aad_pim_active_assignment",
				"aad_pim_eligible_assignment"
			);
			dependsOn = @(

			);
		}
		#Set nulls
		$role_definition = $null
		#Set generic lists
		$all_active_ra = New-Object System.Collections.Generic.List[System.Object]
		$all_eligible_ra = New-Object System.Collections.Generic.List[System.Object]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID Privileged Identity Management",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDPIMInfo');
		}
		Write-Information @msg
		$p = @{
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$role_definition = Get-MonkeyMSPIMRoleDefinition @p
		if ($null -ne $role_definition) {
			#Get active Assignments
			$activeAssignments = $role_definition | Where-Object { $_.activeAssignmentCount -gt 0 }
			#Get eligible Assignments
			$eligibleAssignments = $role_definition | Where-Object { $_.eligibleAssignmentCount -gt 0 }
			if ($null -ne $activeAssignments) {
				foreach ($activeAssignment in $activeAssignments) {
					$p = @{
						RoleDefinitionId = $activeAssignment.templateId;
						AssignmentType = 'Active';
						InformationAction = $O365Object.InformationAction;
						Verbose = $O365Object.Verbose;
						Debug = $O365Object.Debug;
					}
					$active_roles = Get-MonkeyMSPIMRoleAssignment @p
					if ($active_roles) {
						foreach ($arole in $active_roles) {
							#Add to list
							[void]$all_active_ra.Add($arole)
						}
					}
				}
			}
			if ($null -ne $eligibleAssignments) {
				foreach ($eligibleAssignment in $eligibleAssignments) {
					$p = @{
						RoleDefinitionId = $eligibleAssignment.templateId;
						AssignmentType = 'Eligible';
						InformationAction = $O365Object.InformationAction;
						Verbose = $O365Object.Verbose;
						Debug = $O365Object.Debug;
					}
					$eligible_roles = Get-MonkeyMSPIMRoleAssignment @p
					if ($eligible_roles) {
						foreach ($erole in $eligible_roles) {
							#Add to list
							[void]$all_eligible_ra.Add($erole)
						}
					}
				}
			}
		}
	}
	end {
		if ($null -ne $role_definition) {
			$role_definition.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.PIM.RoleDefinition')
			[pscustomobject]$obj = @{
				Data = $role_definition;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_pim_roleDefinition = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID Privileged Identity Management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('EntraIDPIMRoleAssignmentEmptyResponse')
			}
			Write-Verbose @msg
		}
		if ($all_active_ra.Count -gt 0) {
			$all_active_ra.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.PIM.RoleDefinition')
			[pscustomobject]$obj = @{
				Data = $all_active_ra;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_pim_active_assignment = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID Privileged Identity Management active assignments",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('EntraIDPIMActiveRoleAssignmentEmptyResponse')
			}
			Write-Verbose @msg
		}
		if ($all_eligible_ra.Count -gt 0) {
			$all_eligible_ra.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.PIM.RoleDefinition')
			[pscustomobject]$obj = @{
				Data = $all_eligible_ra;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_pim_eligible_assignment = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID Privileged Identity Management eligible assignments",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('EntraIDPIMEligibleRoleAssignmentEmptyResponse')
			}
			Write-Verbose @msg
		}
	}
}







