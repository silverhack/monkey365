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


function Get-MonkeyAZKeyVaultsDiagnosticSetting {
<#
        .SYNOPSIS
		Azure plugin to get all keyvaults diagnostics settings in subscription

        .DESCRIPTION
		Azure plugin to get all keyvaults diagnostics settings in subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZKeyVaultsDiagnosticSetting
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
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00029";
			Provider = "Azure";
			Title = "Plugin to get Azure KeyVault Diagnostic Settings";
			Group = @("KeyVault");
			ServiceName = "Azure KeyVault Diagnostic Settings";
			PluginName = "Get-MonkeyAZKeyVaultsDiagnosticSetting";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Keyvaults
		$KeyVaults = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.KeyVault/*' }
		if (-not $KeyVaults) { continue }
		$all_diag_settings = @();
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Keyvault diagnostic settings",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureKeyVaultDiagSettingsInfo');
		}
		Write-Information @msg
		if ($KeyVaults) {
			foreach ($keyvault in $KeyVaults) {
				$URI = ("{0}{1}/providers/microsoft.insights/diagnosticSettings?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,$keyvault.id,'2017-05-01-preview')
				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$key_vault_diag_settings = Get-MonkeyRMObject @params
				#KeyVault diag setting object
				if ($key_vault_diag_settings.id) {
					$new_key_vault_diag_settings = New-Object -TypeName PSCustomObject
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name id -Value $key_vault_diag_settings.id
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name keyvaultname -Value $keyvault.Name
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name rawObject -Value $key_vault_diag_settings
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name properties -Value $key_vault_diag_settings.Properties
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name name -Value $key_vault_diag_settings.Name
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name location -Value $key_vault_diag_settings.location
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name tags -Value $key_vault_diag_settings.Tags
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name storageAccountId -Value $key_vault_diag_settings.Properties.storageAccountId
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name serviceBusRuleId -Value $key_vault_diag_settings.Properties.serviceBusRuleId
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name workspaceId -Value $key_vault_diag_settings.Properties.workspaceId
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name eventHubAuthorizationRuleId -Value $key_vault_diag_settings.Properties.eventHubAuthorizationRuleId
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name eventHubName -Value $key_vault_diag_settings.Properties.eventHubName
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name logAnalyticsDestinationType -Value $key_vault_diag_settings.Properties.logAnalyticsDestinationType
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name logCategory -Value $key_vault_diag_settings.Properties.logs.category
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name logsEnabled -Value $key_vault_diag_settings.Properties.logs.enabled
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name logsRetentionPolicy -Value $key_vault_diag_settings.Properties.logs.retentionPolicy.enabled
					$new_key_vault_diag_settings | Add-Member -Type NoteProperty -Name logsRetentionPolicyDays -Value $key_vault_diag_settings.Properties.logs.retentionPolicy.Days
					#Add keyvault to array
					$all_diag_settings += $new_key_vault_diag_settings
				}
			}
		}
	}
	end {
		if ($all_diag_settings) {
			$all_diag_settings.PSObject.TypeNames.Insert(0,'Monkey365.Azure.key_vaults.diagnostic_settings')
			[pscustomobject]$obj = @{
				Data = $all_diag_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.az_key_vaults_diag_settings = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure keyvault diagnostic settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureKeyVaultDiagSettingsEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
