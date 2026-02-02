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


function Get-MonkeyAADManagedApplication {
<#
        .SYNOPSIS
		Collector to get managed applications from Microsoft Entra ID

        .DESCRIPTION
		Collector to get managed applications from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADManagedApplication
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
			Id = "aad0030";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADManagedApplication";
			ApiType = "MSGraph";
            objectType = 'EntraManagedApplication';
			description = "Collector to get managed applications from Microsoft Entra ID";
			Group = @(
				"EntraID"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_managed_app";
				"aad_managed_app_perms";
				"aad_user_consented_apps"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get config
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
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID managed applications",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDManagedApplicationInfo');
		}
		Write-Information @msg
		#Get managed applications
		$p = @{
			APIVersion = $aadConf.api_version;
			Expand = 'owners';
			Filter = "tags/Any(monkey: monkey eq 'WindowsAzureActiveDirectoryIntegratedApp')";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$managed_apps = Get-MonkeyMSGraphAADServicePrincipal @p
		#Get service principal permissions
		$p = @{
			ScriptBlock = { Get-MonkeyMSGraphAADServicePrincipalPermission -InputObject $_ };
			Runspacepool = $O365Object.monkey_runspacePool;
			ReuseRunspacePool = $true;
			Debug = $O365Object.VerboseOptions.Debug;
			Verbose = $O365Object.VerboseOptions.Verbose;
			MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
			BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
			BatchSize = $O365Object.nestedRunspaces.BatchSize;
		}
		$managed_app_perms = $managed_apps | Invoke-MonkeyJob @p
		#Get user consented apps
		$p = @{
			APIVersion = $aadConf.api_version;
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$user_consented_apps = Get-MonkeyMSGraphServicePrincipalUserConsentPermission @p
	}
	end {
		#Return managed apps properties
		if ($managed_apps) {
			$managed_apps.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.managed_applications.properties')
			[pscustomobject]$obj = @{
				Data = $managed_apps;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_managed_app = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID managed applications",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('AzureMSGraphManagedAppEmptyResponse')
			}
			Write-Verbose @msg
		}
		#Return managed apps permissions properties
		if ($managed_app_perms) {
			$managed_app_perms.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.managed_applications.permissions')
			[pscustomobject]$obj = @{
				Data = $managed_app_perms;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_managed_app_perms = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID managed app permissions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('AzureMSGraphManagedAppEmptyResponse')
			}
			Write-Verbose @msg
		}
		#Return user consented apps
		if ($user_consented_apps) {
			$user_consented_apps.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.app.user.consent')
			[pscustomobject]$obj = @{
				Data = $user_consented_apps;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_user_consented_apps = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID user consented applications",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('AzureMSGraphAppUserConsentEmptyResponse')
			}
			Write-Verbose @msg
		}
	}
}









