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


function Get-MonkeyEntraIDPortalAdminConsentSetting {
<#
        .SYNOPSIS
		Collector to get admin consent settings from Microsoft Entra ID Portal

        .DESCRIPTION
		Collector to get admin consent settings from Microsoft Entra ID Portal

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEntraIDPortalAdminConsentSetting
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
		$Environment = $O365Object.Environment
		#Collector metadata
		$monkey_metadata = @{
			Id = "aad0037";
			Provider = "EntraID";
			Resource = "EntraIDPortal";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEntraIDPortalAdminConsentSetting";
			ApiType = "EntraIDPortal";
			description = "Collector to get admin consent settings from Microsoft Entra ID Portal";
			Group = @(
				"EntraIDPortal"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_managed_app_admin_consent_setting"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID enterprise applications admin consent settings",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzurePortalManagedAppAdminConsentSettings');
		}
		Write-Information @msg
		#Get Enterprise applications admin consent settings
		$p = @{
			Authentication = $AADAuth;
			Query = "RequestApprovals/V2/PolicyTemplates?type=AdminConsentFlow";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$adminConsentSettings = Get-MonkeyAzurePortalObject @p
		if ($null -eq $adminConsentSettings) {
			$adminConsentSettings = [pscustomobject]@{
				adminConsentEnabled = $false;
				requestExpiresInDays = $false;
				notificationsEnabled = $false;
				remindersEnabled = $false
			}
		}
		else {
			$adminConsentSettings | Add-Member -MemberType NoteProperty -Name adminConsentEnabled -Value $true -Force
		}
	}
	end {
		if ($adminConsentSettings) {
			$adminConsentSettings.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.managed.applications.admin_consent_settings')
			[pscustomobject]$obj = @{
				Data = $adminConsentSettings;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_managed_app_admin_consent_setting = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID enterprise applications admin consent settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalManagedAppAdminConsentSettings');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










