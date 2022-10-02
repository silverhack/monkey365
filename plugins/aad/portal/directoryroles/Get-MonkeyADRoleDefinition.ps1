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


function Get-MonkeyADRoleDefinition {
<#
        .SYNOPSIS
		Plugin to get information about role definitions from Azure AD

        .DESCRIPTION
		Plugin to get information about role definitions from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADRoleDefinition
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		#Getting environment
		#Plugin metadata
		$monkey_metadata = @{
			Id = "aad0006";
			Provider = "AzureAD";
			Title = "Plugin to get information about role definitions from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD Directory Role Definition";
			PluginName = "Get-MonkeyADRoleDefinition";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$Environment = $O365Object.Environment
		#Get Graph Auth
		$graphAuth = $O365Object.auth_tokens.MSGraph
	}
	process {
		if ($null -ne $Environment -and $null -ne $graphAuth) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD role definitions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('AzureADRoleDefinitionsSettings');
			}
			Write-Information @msg
			#Execute query
			$params = @{
				Authentication = $graphAuth;
				ObjectType = "roleManagement/directory/roleDefinitions";
				Environment = $Environment;
				ContentType = 'application/json';
				Method = "GET";
				APIVersion = 'v1.0';
			}
			$role_defs = Get-GraphObject @params
		}
	}
	end {
		if ($role_defs) {
			$role_defs.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.RoleDefinitions')
			[pscustomobject]$obj = @{
				Data = $role_defs;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_role_definitions = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD role definitions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureADRoleDefinitionEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
