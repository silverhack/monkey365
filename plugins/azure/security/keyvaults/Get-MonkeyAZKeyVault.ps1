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


function Get-MonkeyAZKeyVault {
<#
        .SYNOPSIS
		Azure plugin to get all keyvaults in subscription

        .DESCRIPTION
		Azure plugin to get all keyvaults in subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZKeyVault
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
			Id = "az00028";
			Provider = "Azure";
			Title = "Plugin to get Azure Keyvault information";
			Group = @("KeyVault");
			ServiceName = "Azure KeyVault";
			PluginName = "Get-MonkeyAZKeyVault";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Azure Keyvault Auth
		$vault_auth = $O365Object.auth_tokens.AzureVault
		#Get Config
		$keyvault_Config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureKeyVault" } | Select-Object -ExpandProperty resource
		#Get Keyvaults
		$KeyVaults = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.KeyVault/*' }
		#if(-NOT $KeyVaults){continue}
		$all_key_vaults = @();
		$all_keys = @();
		$all_secrets = @();
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure KeyVault",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureKeyVaultInfo');
		}
		Write-Information @msg
		if ($KeyVaults) {
			foreach ($keyvault in $KeyVaults) {
				$URI = ("{0}{1}?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,$keyvault.id,`
 						$keyvault_Config.api_version)

				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$my_key_vault = Get-MonkeyRMObject @params
				#KeyVault object
				$new_key_vault_object = New-Object -TypeName PSCustomObject
				$new_key_vault_object | Add-Member -Type NoteProperty -Name id -Value $my_key_vault.id
				$new_key_vault_object | Add-Member -Type NoteProperty -Name name -Value $my_key_vault.Name
				$new_key_vault_object | Add-Member -Type NoteProperty -Name tags -Value $my_key_vault.Tags
				$new_key_vault_object | Add-Member -Type NoteProperty -Name location -Value $my_key_vault.location
				$new_key_vault_object | Add-Member -Type NoteProperty -Name properties -Value $my_key_vault.Properties
				$new_key_vault_object | Add-Member -Type NoteProperty -Name rawObject -Value $my_key_vault
				$new_key_vault_object | Add-Member -Type NoteProperty -Name skufamily -Value $my_key_vault.Properties.sku.family
				$new_key_vault_object | Add-Member -Type NoteProperty -Name skuname -Value $my_key_vault.Properties.sku.Name
				$new_key_vault_object | Add-Member -Type NoteProperty -Name tenantId -Value $my_key_vault.Properties.TenantID
				$new_key_vault_object | Add-Member -Type NoteProperty -Name vaultUri -Value $my_key_vault.Properties.vaultUri
				$new_key_vault_object | Add-Member -Type NoteProperty -Name provisioningState -Value $my_key_vault.Properties.provisioningState
				$new_key_vault_object | Add-Member -Type NoteProperty -Name enabledForDeployment -Value $my_key_vault.Properties.enabledForDeployment
				$new_key_vault_object | Add-Member -Type NoteProperty -Name enabledForDiskEncryption -Value $my_key_vault.Properties.enabledForDiskEncryption
				$new_key_vault_object | Add-Member -Type NoteProperty -Name enabledForTemplateDeployment -Value $my_key_vault.Properties.enabledForTemplateDeployment
				#Get Logging capabilities
				$URI = ("{0}{1}/providers/microsoft.insights/diagnosticSettings?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,$my_key_vault.id,'2017-05-01-preview')

				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$key_vault_diag_settings = Get-MonkeyRMObject @params
				if ($key_vault_diag_settings.id) {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name keyvaultDagSettings -Value $key_vault_diag_settings
					$new_key_vault_object | Add-Member -Type NoteProperty -Name loggingEnabled -Value $true
					$new_key_vault_object | Add-Member -Type NoteProperty -Name logsRetentionPolicyDays -Value $key_vault_diag_settings.Properties.logs.retentionPolicy.Days
					if ($key_vault_diag_settings.Properties.storageAccountId) {
						$new_key_vault_object | Add-Member -Type NoteProperty -Name storageAccountId -Value $key_vault_diag_settings.Properties.storageAccountId
					}
					else {
						$new_key_vault_object | Add-Member -Type NoteProperty -Name storageAccountId -Value $null
					}
				}
				else {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name keyvaultDagSettings -Value $null
					$new_key_vault_object | Add-Member -Type NoteProperty -Name loggingEnabled -Value $false
					$new_key_vault_object | Add-Member -Type NoteProperty -Name logsRetentionPolicyDays -Value $null
					$new_key_vault_object | Add-Member -Type NoteProperty -Name storageAccountId -Value $null
				}
				#Get Network properties
				if (-not $my_key_vault.Properties.networkAcls) {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name allowAccessFromAllNetworks -Value $true
				}
				elseif ($my_key_vault.Properties.networkAcls.bypass -eq "AzureServices" -and $my_key_vault.Properties.networkAcls.defaultAction -eq "Allow") {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name allowAccessFromAllNetworks -Value $true
				}
				else {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name allowAccessFromAllNetworks -Value $false
				}
				#Get Recoverable options
				if (-not $my_key_vault.Properties.enablePurgeProtection) {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name enablePurgeProtection -Value $false
				}
				else {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name enablePurgeProtection -Value $my_key_vault.Properties.enablePurgeProtection
				}
				if (-not $my_key_vault.Properties.enableSoftDelete) {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name enableSoftDelete -Value $false
				}
				else {
					$new_key_vault_object | Add-Member -Type NoteProperty -Name enableSoftDelete -Value $my_key_vault.Properties.enableSoftDelete
				}
				#Get Keys within vault
				$URI = ("{0}keys?api-version={1}" -f $my_key_vault.Properties.vaultUri,'2016-10-01')

				$params = @{
					Authentication = $vault_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$_keys = Get-MonkeyRMObject @params
				if ($_keys) {
					foreach ($_key in $_keys) {
						if ($_key.kid) {
							$new_key = New-Object -TypeName PSCustomObject
							$new_key | Add-Member -Type NoteProperty -Name keyVaultName -Value $my_key_vault.Name
							$new_key | Add-Member -Type NoteProperty -Name keyVaultId -Value $my_key_vault.id
							$new_key | Add-Member -Type NoteProperty -Name id -Value $_key.kid
							$new_key | Add-Member -Type NoteProperty -Name enabled -Value $_key.Attributes.enabled
							$new_key | Add-Member -Type NoteProperty -Name created -Value $_key.Attributes.created
							$new_key | Add-Member -Type NoteProperty -Name updated -Value $_key.Attributes.updated
							$new_key | Add-Member -Type NoteProperty -Name recoveryLevel -Value $_key.Attributes.recoveryLevel
							$new_key | Add-Member -Type NoteProperty -Name rawObject -Value $_key
							#Check if key expires
							if ($_key.Attributes.exp) {
								$new_key | Add-Member -Type NoteProperty -Name expires -Value $_key.Attributes.exp
							}
							else {
								$new_key | Add-Member -Type NoteProperty -Name expires -Value $false
							}
							#Add object to arrah
							$all_keys += $new_key
						}
					}
					if ($all_keys) {
						$new_key_vault_object | Add-Member -Type NoteProperty -Name keys -Value $all_keys
					}
					else {
						$new_key_vault_object | Add-Member -Type NoteProperty -Name keys -Value $null
					}
				}
				#Get secrets within vault
				$URI = ("{0}secrets?api-version={1}" -f $my_key_vault.Properties.vaultUri,'7.0')

				$params = @{
					Authentication = $vault_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$_secrets = Get-MonkeyRMObject @params
				if ($_secrets) {
					foreach ($_secret in $_secrets) {
						if ($_secret.id) {
							$new_secret = New-Object -TypeName PSCustomObject
							$new_secret | Add-Member -Type NoteProperty -Name keyVaultName -Value $my_key_vault.Name
							$new_secret | Add-Member -Type NoteProperty -Name keyVaultId -Value $my_key_vault.id
							$new_secret | Add-Member -Type NoteProperty -Name id -Value $_secret.id
							$new_secret | Add-Member -Type NoteProperty -Name enabled -Value $_secret.Attributes.enabled
							$new_secret | Add-Member -Type NoteProperty -Name created -Value $_secret.Attributes.created
							$new_secret | Add-Member -Type NoteProperty -Name updated -Value $_secret.Attributes.updated
							$new_secret | Add-Member -Type NoteProperty -Name recoveryLevel -Value $_secret.Attributes.recoveryLevel
							$new_secret | Add-Member -Type NoteProperty -Name rawObject -Value $_secret
							#Check if key expires
							if ($_secret.Attributes.exp) {
								$new_secret | Add-Member -Type NoteProperty -Name expires -Value $_secret.Attributes.exp
							}
							else {
								$new_secret | Add-Member -Type NoteProperty -Name expires -Value $false
							}
							#Add object to arrah
							$all_secrets += $new_secret
						}
					}
					if ($all_secrets) {
						$new_key_vault_object | Add-Member -Type NoteProperty -Name secrets -Value $all_secrets
					}
					else {
						$new_key_vault_object | Add-Member -Type NoteProperty -Name secrets -Value $null
					}
				}
				#Add keyvault to array
				$all_key_vaults += $new_key_vault_object
			}
		}
	}
	end {
		if ($all_key_vaults) {
			$all_key_vaults.PSObject.TypeNames.Insert(0,'Monkey365.Azure.KeyVaults')
			[pscustomobject]$obj = @{
				Data = $all_key_vaults;
				Metadata = $monkey_metadata;
			}
			$returnData.az_key_vaults = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure KeyVaults",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureKeyVaultsEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
