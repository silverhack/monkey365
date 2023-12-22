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


function Get-MonkeyAADApplication {
<#
        .SYNOPSIS
		Collector to get app registration info from Microsoft Entra ID

        .DESCRIPTION
		Collector to get app registration info from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADApplication
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
			Id = "aad0001";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADApplication";
			ApiType = "MSGraph";
			description = "Collector to get app registration info from Microsoft Entra ID";
			Group = @(
				"EntraID"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"aad_app_registrations",
				"aad_app_permissions"
			);
			dependsOn = @(

			);
		}
		#Get Config
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
        $app_perms = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID applications",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDMSGraphApplication');
		}
		Write-Information @msg
		#Get applications
		$p = @{
			APIVersion = $aadConf.api_version;
			Expand = 'owners';
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$all_applications = Get-MonkeyMSGraphAADApplication @p | Format-AADApplicationCredential
		#Get Application permissions

		$p = @{
			ScriptBlock = { Get-MonkeyMSGraphAADAPPPermission -Application $_ };
			Runspacepool = $O365Object.monkey_runspacePool;
			ReuseRunspacePool = $true;
			Debug = $O365Object.VerboseOptions.Debug;
			Verbose = $O365Object.VerboseOptions.Verbose;
			MaxQueue = $O365Object.MaxQueue;
			BatchSleep = $O365Object.BatchSleep;
			BatchSize = $O365Object.BatchSize;
		}
        $app_perms = $all_applications | Invoke-MonkeyJob @p
		<#
		#Get libs for runspace
        $rsOptions = Initialize-MonkeyScan -Provider EntraID
        $p = @{
            Command = "Get-MonkeyMSGraphAADAPPPermission";
            ImportCommands = $rsOptions.libCommands;
            ImportVariables = $O365Object.runspace_vars;
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
        #>
	}
	end {
		if ($all_applications) {
			$all_applications.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.app_registrations')
			[pscustomobject]$obj = @{
				Data = $all_applications;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_app_registrations = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID applications",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('AzureMSGraphApplicationsEmptyResponse')
			}
			Write-Verbose @msg
		}
		if ($app_perms) {
			$app_perms.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.application_permissions')
			[pscustomobject]$obj = @{
				Data = $app_perms;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_app_permissions = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID application's permissions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('AzureMSGraphAppRBACEmptyResponse')
			}
			Write-Verbose @msg
		}
	}
}







