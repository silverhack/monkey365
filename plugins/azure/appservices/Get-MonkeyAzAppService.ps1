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


function Get-MonkeyAzAppService {
<#
        .SYNOPSIS
		Plugin to get information from Azure App Services

        .DESCRIPTION
		Plugin to get information from Azure App Services

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAppService
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
		#Import Localized data
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00002";
			Provider = "Azure";
			Title = "Plugin to get information from Azure App Services";
			Group = @("AppServices");
			ServiceName = "Azure App Services";
			PluginName = "Get-MonkeyAzAppService";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		$AzureWebApps = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureWebApps" } | Select-Object -ExpandProperty resource
		#Get all sites
		$app_services = $O365Object.all_resources | Where-Object { $_.type -eq 'Microsoft.Web/sites' }
		if (-not $app_services) { continue }
		#Create array
		$AllMyWebApps = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure app services",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureAPPServices');
		}
		Write-Information @msg
		if ($app_services) {
			foreach ($new_app in $app_services) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $new_app.Name,'app service');
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureAppServicesInfoMessage');
				}
				Write-Information @msg
				#Construct URI
				$URI = ("{0}{1}?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,$new_app.id,`
 						$AzureWebApps.api_version)

				#launch request
				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$app = Get-MonkeyRMObject @params
				if ($app.id) {
					#Get Web app config
					$URI = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,$app.id,"config","2016-08-01")
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $URI;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$appConfiguration = Get-MonkeyRMObject @params
					#TODO ADD IP_RESTRICTIONS
					#$appConfiguration.properties.ipSecurityRestrictions -ForegroundColor Yellow
					if ($appConfiguration) {
						$app | Add-Member -Type NoteProperty -Name Configuration -Value $appConfiguration
					}
					#Get siteAuth settings
					try {
						$PostData = @{ "resourceUri" = $app.id } | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
						$URI = ("{0}/api/Websites/GetSiteAuthSettings" -f $O365Object.Environment.WebAppServicePortal)
						$params = @{
							Authentication = $rm_auth;
							OwnQuery = $URI;
							Environment = $Environment;
							ContentType = 'application/json';
							Method = "POST";
							Data = $PostData;
						}
						$appAuthSettings = Get-MonkeyRMObject @params
						if ($appAuthSettings) {
							$app | Add-Member -Type NoteProperty -Name siteAuthSettings -Value $appAuthSettings
						}
					}
					catch {
						$msg = @{
							MessageData = $_;
							callStack = (Get-PSCallStack | Select-Object -First 1);
							logLevel = 'error';
							InformationAction = $InformationAction;
							Tags = @('AzureAppServicesErrorMessage');
						}
						Write-Error @msg
						#Debug error
						$msg = @{
							MessageData = $_.Exception.StackTrace;
							callStack = (Get-PSCallStack | Select-Object -First 1);
							logLevel = 'debug';
							InformationAction = $InformationAction;
							Tags = @('AzureAppServicesDebugErrorMessage');
						}
						Write-Debug @msg
					}
					#Get Backup counts
					$URI = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,$app.id,"backups","2016-08-01")
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $URI;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$appBackup = Get-MonkeyRMObject @params
					if ($appBackup) {
						#Add to object
						$app | Add-Member -Type NoteProperty -Name backupCount -Value $appBackup.value.Count
						$app | Add-Member -Type NoteProperty -Name backupInfo -Value $appBackup
					}
					else {
						$app | Add-Member -Type NoteProperty -Name backupCount -Value 0
						$app | Add-Member -Type NoteProperty -Name backupInfo -Value $null
					}
					#Get snapShot counts
					$URI = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,$app.id,"config/web/snapshots","2016-08-01")
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $URI;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$appSnapShots = Get-MonkeyRMObject @params
					if ($appSnapShots) {
						#Add to object
						$app | Add-Member -Type NoteProperty -Name snapshotCount -Value $appSnapShots.Properties.Count
						$app | Add-Member -Type NoteProperty -Name SnapShotInfo -Value $appSnapShots
					}
					else {
						$app | Add-Member -Type NoteProperty -Name snapshotCount -Value 0
						$app | Add-Member -Type NoteProperty -Name SnapShotInfo -Value $null
					}
					#Decorate object
					$app.PSObject.TypeNames.Insert(0,'Monkey365.Azure.WebApp')
					$AllMyWebApps += $app
				}
			}
		}
	}
	end {
		if ($AllMyWebApps) {
			$AllMyWebApps.PSObject.TypeNames.Insert(0,'Monkey365.Azure.WebApps')
			[pscustomobject]$obj = @{
				Data = $AllMyWebApps;
				Metadata = $monkey_metadata;
			}
			$returnData.az_app_services = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure app services",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureAppServicesEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
