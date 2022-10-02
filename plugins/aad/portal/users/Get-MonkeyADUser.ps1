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


function Get-MonkeyADUser {
<#
        .SYNOPSIS
		Plugin to get users from Azure AD using graph API

        .DESCRIPTION
		Plugin to get users from Azure AD using graph API

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADUser
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
		$Environment = $O365Object.Environment
		#Plugin metadata
		$monkey_metadata = @{
			Id = "aad0009";
			Provider = "AzureAD";
			Title = "Plugin to get users from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD Users";
			PluginName = "Get-MonkeyADUser";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Azure Graph Auth
		$GraphAuth = $O365Object.auth_tokens.MSGraph
		#create array
		$all_users = New-Object System.Collections.Generic.List[System.Object]
		#Generate vars
		$vars = @{
			"O365Object" = $O365Object;
			"WriteLog" = $WriteLog;
			'Verbosity' = $Verbosity;
			'InformationAction' = $InformationAction;
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD Users using Graph API",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalUsers');
		}
		Write-Information @msg
		#Get Users
		$params = @{
			Authentication = $GraphAuth;
			ObjectType = "users";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			APIVersion = 'beta';
		}
		$tmp_users = Get-GraphObject @params
		if ($tmp_users) {
			if ([System.Convert]::ToBoolean($AADConfig.GetUserDetails)) {
				$param = @{
					ScriptBlock = { Get-MonkeyADPortalDetailedUser -user $_ };
					ImportCommands = $O365Object.LibUtils;
					ImportVariables = $vars;
					ImportModules = $O365Object.runspaces_modules;
					StartUpScripts = $O365Object.runspace_init;
					ThrowOnRunspaceOpenError = $true;
					Debug = $O365Object.VerboseOptions.Debug;
					Verbose = $O365Object.VerboseOptions.Verbose;
					Throttle = $O365Object.nestedRunspaceMaxThreads;
					MaxQueue = $O365Object.MaxQueue;
					BatchSleep = $O365Object.BatchSleep;
					BatchSize = $O365Object.BatchSize;
				}
				$all_users = $tmp_users | Invoke-MonkeyJob @param
			}
			else {
				$all_users = $tmp_users;
			}
		}
	}
	end {
		if ($all_users) {
			#$all_users = $all_users| Select-Object $AADConfig.UsersFilter
			$all_users.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.Users')
			[pscustomobject]$obj = @{
				Data = $all_users;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_domain_users = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Users",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalUsersEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
