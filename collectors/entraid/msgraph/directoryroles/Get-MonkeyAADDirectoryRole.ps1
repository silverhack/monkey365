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

function Get-MonkeyAADDirectoryRole {
<#
        .SYNOPSIS
		Collector to get Directoryroles from Microsoft Entra ID
        https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles

        .DESCRIPTION
		Collector to get Directoryroles from Microsoft Entra ID
        https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADDirectoryRole
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
			Id = "aad0005";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADDirectoryRole";
			ApiType = "MSGraph";
			description = "Collector to get Directoryroles from Microsoft Entra ID";
			Group = @(
				"EntraID"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_directory_roles";
				"aad_role_assignment"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		try {
			$aadConf = $O365Object.internal_config.entraId.Provider.msgraph
		}
		catch {
			$msg = @{
				MessageData = ($message.MonkeyInternalConfigError);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'verbose';
				InformationAction = $O365Object.InformationAction;
				Tags = @('Monkey365ConfigError');
			}
			Write-Verbose @msg
			break
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID Directory Roles",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureMSGraphDirectoryRole');
		}
		Write-Information @msg
		#Get Entra ID role assignment
		$p = @{
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
			APIVersion = $aadConf.api_version;
		}
		$aad_role_assignment = Get-MonkeyMSGraphEntraRoleAssignment @p
	}
	End {
		If ($aad_role_assignment) {
			$aad_role_assignment.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.RoleAssignment')
			[pscustomobject]$obj = @{
				Data = $aad_role_assignment;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_role_assignment = $obj
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID role assignment",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'verbose';
				Tags = @('AzureGraphUsersEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}





