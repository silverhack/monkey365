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


function Get-MonkeyAzRoleAssignment {
<#
        .SYNOPSIS
		Collector to get Role assignments from Azure

        .DESCRIPTION
		Collector to get Role assignments from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZRoleAssignment
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
			Id = "az00105";
			Provider = "Azure";
			Resource = "RoleAssignment";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZRoleAssignment";
			ApiType = "resourceManagement";
			description = "Collector to get Role assignments from Azure";
			Group = @(
				"RoleAssignment"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"az_rbac_users",
				"az_classic_admins",
				"az_role_definitions"
			);
			dependsOn = @(

			);
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Role Based Access Control",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureRBACInfo');
		}
		Write-Information @msg
		#Get classic administrators
		$classic_admins = Get-MonkeyAzClassicAdministrator
		#Get Role definitions
		$role_definintions = Get-MonkeyAzRoleDefinitionObject
		#Get role assignment
		$role_assignment = Get-MonkeyAzIAMPermission
	}
	end {
		if ($role_assignment) {
			$role_assignment.PSObject.TypeNames.Insert(0,'Monkey365.Azure.RoleAssignment')
			[pscustomobject]$obj = @{
				Data = $role_assignment;
				Metadata = $monkey_metadata;
			}
			$returnData.az_rbac_users = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Role Access Based Control",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureRBACEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		if ($classic_admins) {
			$classic_admins.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ClassicAdministrator')
			[pscustomobject]$obj = @{
				Data = $classic_admins;
				Metadata = $monkey_metadata;
			}
			$returnData.az_classic_admins = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Classic Admins",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureClassicAdminsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		if ($role_definintions) {
			$role_definintions.PSObject.TypeNames.Insert(0,'Monkey365.Azure.RoleDefinitions')
			[pscustomobject]$obj = @{
				Data = $role_definintions;
				Metadata = $monkey_metadata;
			}
			$returnData.az_role_definitions = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Role Definitions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureRoleDefinitionsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







