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




function Get-MonkeyAZStorageAccount {
<#
        .SYNOPSIS
		Plugin extract Storage Account information from Azure
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-https-stor-acct
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-store-file-enc

        .DESCRIPTION
		Plugin extract Storage Account information from Azure
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-https-stor-acct
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-store-file-enc

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZStorageAccount
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
			Id = "az00040";
			Provider = "Azure";
			Title = "Plugin to get information from Azure Storage account";
			Group = @("StorageAccounts");
			ServiceName = "Azure Storage account";
			PluginName = "Get-MonkeyAZStorageAccount";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Azure Storage Auth
		$StorageAuth = $O365Object.auth_tokens.AzureStorage
		#Get Config
		$AzureStorageAccountConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureStorage" } | Select-Object -ExpandProperty resource
		#Get Storage accounts
		$storage_accounts = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Storage/storageAccounts' }
		if (-not $storage_accounts) { continue }
		#Set arrays
		$AllStorageAccounts = @()
		$AllStorageAccountsPublicBlobs = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Storage accounts",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureStorageAccountsInfo');
		}
		Write-Information @msg
		#Get all alerts
		$current_date = [datetime]::Now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
		$90_days = [datetime]::Now.AddDays(-89).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
		$tmp_filter = ("eventTimestamp ge \'{0}\' and eventTimestamp le \'{1}\'" -f $90_days,$current_date)
		$filter = [System.Text.RegularExpressions.Regex]::Unescape($tmp_filter)
		$URI = ('{0}{1}/providers/microsoft.insights/eventtypes/management/values?api-Version={2}&$filter={3}' `
 				-f $O365Object.Environment.ResourceManager,$O365Object.current_subscription.id,'2017-03-01-preview',$filter)

		$params = @{
			Authentication = $rm_auth;
			OwnQuery = $URI;
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
		}
		$all_alerts = Get-MonkeyRMObject @params
		if ($storage_accounts) {
			foreach ($str_account in $storage_accounts) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $str_account.Name,"Storage account");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureStorageAccountInfo');
				}
				Write-Information @msg
				#Construct URI
				$URI = ("{0}{1}?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,`
 						$str_account.id,$AzureStorageAccountConfig.api_version)

				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$StorageAccount = Get-MonkeyRMObject @params
				if ($StorageAccount.id) {
					$msg = @{
						MessageData = ($message.StorageAccountFoundMessage -f $StorageAccount.Name,$StorageAccount.location);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'verbose';
						InformationAction = $InformationAction;
						Tags = @('AzureStorageAccountInfo');
					}
					Write-Verbose @msg
					#Get Key rotation info
					$last_rotation_dates = $all_alerts | Where-Object { $_.resourceId -eq $StorageAccount.id -and $_.authorization.action -eq "Microsoft.Storage/storageAccounts/regenerateKey/action" -and $_.status.localizedValue -eq "Succeeded" } | Select-Object -ExpandProperty eventTimestamp
					$last_rotated_date = $last_rotation_dates | Select-Object -First 1
					#Iterate through properties
					foreach ($properties in $StorageAccount.Properties) {
						$StrAccount = New-Object -TypeName PSCustomObject
						$StrAccount | Add-Member -Type NoteProperty -Name id -Value $StorageAccount.id
						$StrAccount | Add-Member -Type NoteProperty -Name name -Value $StorageAccount.Name
						$StrAccount | Add-Member -Type NoteProperty -Name location -Value $StorageAccount.location
						$StrAccount | Add-Member -Type NoteProperty -Name tags -Value $StorageAccount.Tags
						$StrAccount | Add-Member -Type NoteProperty -Name rawObject -Value $StorageAccount
						$StrAccount | Add-Member -Type NoteProperty -Name properties -Value $properties
						$StrAccount | Add-Member -Type NoteProperty -Name ResourceGroupName -Value $StorageAccount.id.Split("/")[4]
						$StrAccount | Add-Member -Type NoteProperty -Name Kind -Value $StorageAccount.kind
						$StrAccount | Add-Member -Type NoteProperty -Name SkuName -Value $StorageAccount.sku.Name
						$StrAccount | Add-Member -Type NoteProperty -Name SkuTier -Value $StorageAccount.sku.tier
						$StrAccount | Add-Member -Type NoteProperty -Name CreationTime -Value $properties.CreationTime
						$StrAccount | Add-Member -Type NoteProperty -Name primaryLocation -Value $properties.primaryLocation
						$StrAccount | Add-Member -Type NoteProperty -Name statusofPrimary -Value $properties.statusOfPrimary
						$StrAccount | Add-Member -Type NoteProperty -Name supportsHttpsTrafficOnly -Value $properties.supportsHttpsTrafficOnly
						$StrAccount | Add-Member -Type NoteProperty -Name blobEndpoint -Value $properties.primaryEndpoints.blob
						$StrAccount | Add-Member -Type NoteProperty -Name queueEndpoint -Value $properties.primaryEndpoints.queue
						$StrAccount | Add-Member -Type NoteProperty -Name tableEndpoint -Value $properties.primaryEndpoints.table
						$StrAccount | Add-Member -Type NoteProperty -Name fileEndpoint -Value $properties.primaryEndpoints.file
						$StrAccount | Add-Member -Type NoteProperty -Name webEndpoint -Value $properties.primaryEndpoints.web
						$StrAccount | Add-Member -Type NoteProperty -Name dfsEndpoint -Value $properties.primaryEndpoints.dfs
						#Translate Key rotation info
						if ($last_rotation_dates.Count -ge 2) {
							$StrAccount | Add-Member -Type NoteProperty -Name isKeyRotated -Value $true
							$StrAccount | Add-Member -Type NoteProperty -Name lastRotatedKeys -Value $last_rotated_date
						}
						else {
							$StrAccount | Add-Member -Type NoteProperty -Name isKeyRotated -Value $false
							$StrAccount | Add-Member -Type NoteProperty -Name lastRotatedKeys -Value $null
						}
						#Check if using Own key
						if ($properties.encryption.keyvaultproperties) {
							$StrAccount | Add-Member -Type NoteProperty -Name keyvaulturi -Value $properties.encryption.keyvaultproperties.keyvaulturi
							$StrAccount | Add-Member -Type NoteProperty -Name keyname -Value $properties.encryption.keyvaultproperties.keyname
							$StrAccount | Add-Member -Type NoteProperty -Name keyversion -Value $properties.encryption.keyvaultproperties.keyversion
							$StrAccount | Add-Member -Type NoteProperty -Name usingOwnKey -Value $true
						}
						else {
							$StrAccount | Add-Member -Type NoteProperty -Name usingOwnKey -Value $false
						}
						#Getting storage service conf
						$str_service_uri = ("https://{0}.blob.core.windows.net?restype=service&comp=properties" -f $StorageAccount.Name)
						$params = @{
							Authentication = $StorageAuth;
							OwnQuery = $str_service_uri;
							Environment = $Environment;
							ContentType = 'application/json';
							Headers = @{ 'x-ms-version' = '2020-08-04' }
							Method = "GET";
						}
						[xml]$str_service_data = Get-MonkeyRMObject @params
						if ($str_service_data) {
							#Get logging properties
							$str_logging = $str_service_data.StorageServiceProperties | Select-Object -ExpandProperty Logging
							#Get deletion retention policy
							$str_deleteRetentionPolicy = $str_service_data.StorageServiceProperties | Select-Object -ExpandProperty deleteRetentionPolicy
							#Get CORS
							$str_cors = $str_service_data.StorageServiceProperties | Select-Object -ExpandProperty Cors
							#Add to storage account object
							if ($str_cors) {
								$StrAccount | Add-Member -Type NoteProperty -Name cors -Value $str_cors
							}
							if ($str_deleteRetentionPolicy) {
								$StrAccount | Add-Member -Type NoteProperty -Name deleteRetentionPolicy -Value $str_deleteRetentionPolicy
							}
							#Add logging
							if ($str_logging) {
								$StrAccount | Add-Member -Type NoteProperty -Name logging -Value $str_logging
							}
						}
						#Search for public blobs
						#If no public blobs were returned the request will raise a HTTP/1.1 403 AuthorizationPermissionMismatch
						$blob_container_uri = ("https://{0}.blob.core.windows.net?restype=container&comp=list" -f $StorageAccount.Name)
						$params = @{
							Authentication = $StorageAuth;
							OwnQuery = $blob_container_uri;
							Environment = $Environment;
							ContentType = 'application/json';
							Headers = @{ 'x-ms-version' = '2020-08-04' }
							Method = "GET";
						}
						[xml]$blobs = Get-MonkeyRMObject @params
						$all_blobs = $blobs.EnumerationResults.Containers.Container #| Where-Object {$_.Properties.PublicAccess}
						if ($all_blobs) {
							foreach ($public_container in $all_blobs) {
								$container = New-Object -TypeName PSCustomObject
								$container | Add-Member -Type NoteProperty -Name storageaccount -Value $StorageAccount.Name
								$container | Add-Member -Type NoteProperty -Name containername -Value $public_container.Name
								$container | Add-Member -Type NoteProperty -Name blobname -Value $public_container.Name
								$container | Add-Member -Type NoteProperty -Name rawObject -Value $public_container
								if ($public_container.Properties.publicaccess) {
									$container | Add-Member -Type NoteProperty -Name publicaccess -Value $public_container.Properties.publicaccess
								}
								else {
									$container | Add-Member -Type NoteProperty -Name publicaccess -Value "private"
								}
								#Add to array
								$AllStorageAccountsPublicBlobs += $container
							}
						}
						#Get Encryption Status
						if ($properties.encryption.services.blob) {
							$StrAccount | Add-Member -Type NoteProperty -Name isBlobEncrypted -Value $properties.encryption.services.blob.enabled
							$StrAccount | Add-Member -Type NoteProperty -Name lastBlobEncryptionEnabledTime -Value $properties.encryption.services.blob.lastEnabledTime
						}
						if ($properties.encryption.services.file) {
							$StrAccount | Add-Member -Type NoteProperty -Name isFileEncrypted -Value $properties.encryption.services.file.enabled
							$StrAccount | Add-Member -Type NoteProperty -Name lastFileEnabledTime -Value $properties.encryption.services.file.lastEnabledTime
						}
						else {
							$StrAccount | Add-Member -Type NoteProperty -Name isEncrypted -Value $false
							$StrAccount | Add-Member -Type NoteProperty -Name lastEnabledTime -Value $false
						}
						#Get Network Configuration Status
						if ($properties.networkAcls) {
							$fwconf = $properties.networkAcls
							if ($fwconf.bypass -eq 'AzureServices') {
								$StrAccount | Add-Member -Type NoteProperty -Name AllowAzureServices -Value $true
							}
							else {
								$StrAccount | Add-Member -Type NoteProperty -Name AllowAzureServices -Value $false
							}
							if (-not $fwconf.virtualNetworkRules -and -not $fwconf.ipRules -and $fwconf.defaultAction -eq 'Allow') {
								$StrAccount | Add-Member -Type NoteProperty -Name AllowAccessFromAllNetworks -Value $true
							}
							else {
								$StrAccount | Add-Member -Type NoteProperty -Name AllowAccessFromAllNetworks -Value $false
							}
						}
						#Get Data protection for storage account
						$uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,$StorageAccount.id,"blobServices/default","2021-06-01")
						$param = @{
							Authentication = $rm_auth;
							OwnQuery = $uri;
							Environment = $Environment;
							ContentType = 'application/json';
							Headers = @{ 'x-ms-version' = '2020-08-04' }
							Method = "GET";
						}
						$storage_data_protection = Get-MonkeyRMObject @param
						if ($storage_data_protection) {
							$StrAccount | Add-Member -Type NoteProperty -Name dataProtection -Value $storage_data_protection
						}
						#Get ATP for Storage Account
						$uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,$StorageAccount.id,"providers/Microsoft.Security/advancedThreatProtectionSettings/current","2017-08-01-preview")
						$params = @{
							Authentication = $rm_auth;
							OwnQuery = $uri;
							Environment = $Environment;
							ContentType = 'application/json';
							Headers = @{ 'x-ms-version' = '2020-08-04' }
							Method = "GET";
						}
						$StrAccountATPInfo = Get-MonkeyRMObject @params
						if ($StrAccountATPInfo) {
							$StrAccount | Add-Member -Type NoteProperty -Name AdvancedProtectionEnabled -Value $StrAccountATPInfo.Properties.isEnabled
							$StrAccount | Add-Member -Type NoteProperty -Name ATPRawObject -Value $StrAccountATPInfo
						}
						#Get Diagnostic data for storage account
						$URI_keys = ("{0}{1}/listKeys?api-version={2}" -f $O365Object.Environment.ResourceManager,`
 								$StorageAccount.id,
							$AzureStorageAccountConfig.api_version)
						$params = @{
							Authentication = $rm_auth;
							OwnQuery = $URI_keys;
							Environment = $Environment;
							ContentType = 'application/json';
							Headers = @{ 'x-ms-version' = '2020-08-04' }
							Method = "POST";
						}
						$strkeys = Get-MonkeyRMObject @params
						#get key1
						$key1 = $strkeys.keys | Where-Object { $_.keyname -eq 'key1' } | Select-Object -ExpandProperty value
						if ($key1) {
							$queueEndpoint = $properties.primaryEndpoints.queue
							$blobEndpoint = $properties.primaryEndpoints.blob
							$tableEndpoint = $properties.primaryEndpoints.table
							$fileEndpoint = $properties.primaryEndpoints.file
							#Get Shared Access Signature
							$QueueSAS = Get-SASUri -HostName $queueEndpoint -accessKey $key1
							if ($QueueSAS) {
								#Get Queue diagnostig settings
								$params = @{
									url = $QueueSAS;
									Method = "GET";
									UserAgent = $O365Object.UserAgent;
									Headers = @{ 'x-ms-version' = '2020-08-04' }
								}
								[xml]$QueueDiagSettings = Invoke-UrlRequest @params
								if ($QueueDiagSettings) {
									#Add to psobject
									$StrAccount | Add-Member -Type NoteProperty -Name queueLogVersion -Value $QueueDiagSettings.StorageServiceProperties.Logging.version
									$StrAccount | Add-Member -Type NoteProperty -Name queueLogReadEnabled -Value $QueueDiagSettings.StorageServiceProperties.Logging.Read
									$StrAccount | Add-Member -Type NoteProperty -Name queueLogWriteEnabled -Value $QueueDiagSettings.StorageServiceProperties.Logging.Write
									$StrAccount | Add-Member -Type NoteProperty -Name queueLogDeleteEnabled -Value $QueueDiagSettings.StorageServiceProperties.Logging.Delete
									$StrAccount | Add-Member -Type NoteProperty -Name queueRetentionPolicyEnabled -Value $QueueDiagSettings.StorageServiceProperties.Logging.retentionPolicy.enabled
									if ($QueueDiagSettings.StorageServiceProperties.Logging.retentionPolicy.Days) {
										$StrAccount | Add-Member -Type NoteProperty -Name queueRetentionPolicyDays -Value $QueueDiagSettings.StorageServiceProperties.Logging.retentionPolicy.Days
									}
									else {
										$StrAccount | Add-Member -Type NoteProperty -Name queueRetentionPolicyDays -Value $null
									}
								}
							}
							#Get Shared Access Signature
							$tableSAS = Get-SASUri -HostName $tableEndpoint -accessKey $key1
							if ($tableSAS) {
								#Get Queue diagnostig settings
								$params = @{
									url = $tableSAS;
									Method = "GET";
									UserAgent = $O365Object.UserAgent;
									Headers = @{ 'x-ms-version' = '2020-08-04' }
								}
								[xml]$TableDiagSettings = Invoke-UrlRequest @params
								if ($TableDiagSettings) {
									#Add to psobject
									$StrAccount | Add-Member -Type NoteProperty -Name tableLogVersion -Value $TableDiagSettings.StorageServiceProperties.Logging.version
									$StrAccount | Add-Member -Type NoteProperty -Name tableLogReadEnabled -Value $TableDiagSettings.StorageServiceProperties.Logging.Read
									$StrAccount | Add-Member -Type NoteProperty -Name tableLogWriteEnabled -Value $TableDiagSettings.StorageServiceProperties.Logging.Write
									$StrAccount | Add-Member -Type NoteProperty -Name tableLogDeleteEnabled -Value $TableDiagSettings.StorageServiceProperties.Logging.Delete
									$StrAccount | Add-Member -Type NoteProperty -Name tableRetentionPolicyEnabled -Value $TableDiagSettings.StorageServiceProperties.Logging.retentionPolicy.enabled
									if ($TableDiagSettings.StorageServiceProperties.Logging.retentionPolicy.Days) {
										$StrAccount | Add-Member -Type NoteProperty -Name tableRetentionPolicyDays -Value $TableDiagSettings.StorageServiceProperties.Logging.retentionPolicy.Days
									}
									else {
										$StrAccount | Add-Member -Type NoteProperty -Name tableRetentionPolicyDays -Value $null
									}
								}
							}
							#Get Shared Access Signature
							$fileSAS = Get-SASUri -HostName $fileEndpoint -accessKey $key1
							if ($fileSAS) {
								#Get Queue diagnostig settings
								$params = @{
									url = $fileSAS;
									Method = "GET";
									UserAgent = $O365Object.UserAgent;
									Headers = @{ 'x-ms-version' = '2020-08-04' }
								}
								[xml]$FileDiagSettings = Invoke-UrlRequest @params
								if ($FileDiagSettings) {
									#Add to psobject
									$StrAccount | Add-Member -Type NoteProperty -Name fileHourMetricsVersion -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.version
									$StrAccount | Add-Member -Type NoteProperty -Name fileHourMetricsEnabled -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.enabled
									$StrAccount | Add-Member -Type NoteProperty -Name fileHourMetricsIncludeAPIs -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.IncludeAPIs
									$StrAccount | Add-Member -Type NoteProperty -Name fileHourMetricsRetentionPolicyEnabled -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.retentionPolicy.enabled
									if ($FileDiagSettings.StorageServiceProperties.HourMetrics.retentionPolicy.Days) {
										$StrAccount | Add-Member -Type NoteProperty -Name fileHourMetricsRetentionPolicyDays -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.retentionPolicy.Days
									}
									else {
										$StrAccount | Add-Member -Type NoteProperty -Name fileHourMetricsRetentionPolicyDays -Value $null
									}
									#Add to psobject
									$StrAccount | Add-Member -Type NoteProperty -Name fileMinuteMetricsVersion -Value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.version
									$StrAccount | Add-Member -Type NoteProperty -Name fileMinuteMetricsEnabled -Value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.enabled
									$StrAccount | Add-Member -Type NoteProperty -Name fileMinuteMetricsRetentionPolicyEnabled -Value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.retentionPolicy.enabled
									if ($FileDiagSettings.StorageServiceProperties.MinuteMetrics.retentionPolicy.Days) {
										$StrAccount | Add-Member -Type NoteProperty -Name fileMinuteMetricsRetentionPolicyDays -Value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.retentionPolicy.Days
									}
									else {
										$StrAccount | Add-Member -Type NoteProperty -Name fileMinuteMetricsRetentionPolicyDays -Value $null
									}
								}
							}
							#Get Shared Access Signature
							$blobSAS = Get-SASUri -HostName $blobEndpoint -accessKey $key1
							if ($blobSAS) {
								#Get Blob diagnostig settings
								$params = @{
									url = $blobSAS;
									Method = "GET";
									UserAgent = $O365Object.UserAgent;
									Headers = @{ 'x-ms-version' = '2020-08-04' }
								}
								[xml]$BlobDiagSettings = Invoke-UrlRequest @params
								if ($BlobDiagSettings) {
									#Add to psobject
									$StrAccount | Add-Member -Type NoteProperty -Name blobLogVersion -Value $BlobDiagSettings.StorageServiceProperties.Logging.version
									$StrAccount | Add-Member -Type NoteProperty -Name blobLogReadEnabled -Value $BlobDiagSettings.StorageServiceProperties.Logging.Read
									$StrAccount | Add-Member -Type NoteProperty -Name blobLogWriteEnabled -Value $BlobDiagSettings.StorageServiceProperties.Logging.Write
									$StrAccount | Add-Member -Type NoteProperty -Name blobLogDeleteEnabled -Value $BlobDiagSettings.StorageServiceProperties.Logging.Delete
									$StrAccount | Add-Member -Type NoteProperty -Name blobRetentionPolicyEnabled -Value $BlobDiagSettings.StorageServiceProperties.Logging.retentionPolicy.enabled
									if ($BlobDiagSettings.StorageServiceProperties.Logging.retentionPolicy.Days) {
										$StrAccount | Add-Member -Type NoteProperty -Name blobRetentionPolicyDays -Value $BlobDiagSettings.StorageServiceProperties.Logging.retentionPolicy.Days
									}
									else {
										$StrAccount | Add-Member -Type NoteProperty -Name blobRetentionPolicyDays -Value $null
									}
								}
							}
						}
					}
					#Decore Object
					$StrAccount.PSObject.TypeNames.Insert(0,'Monkey365.Azure.StorageAccount')
					#Add to Object
					$AllStorageAccounts += $StrAccount
				}
			}
		}
	}
	end {
		if ($AllStorageAccounts) {
			$AllStorageAccounts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.StorageAccounts')
			[pscustomobject]$obj = @{
				Data = $AllStorageAccounts;
				Metadata = $monkey_metadata;
			}
			$returnData.az_storage_accounts = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Storage accounts",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureStorageAccountsEmptyResponse');
			}
			Write-Warning @msg
		}
		if ($AllStorageAccountsPublicBlobs) {
			#Add public blobs
			$AllStorageAccountsPublicBlobs.PSObject.TypeNames.Insert(0,'Monkey365.Azure.StorageAccounts.PublicBlobs')
			[pscustomobject]$obj = @{
				Data = $AllStorageAccountsPublicBlobs;
				Metadata = $monkey_metadata;
			}
			$returnData.az_storage_public_blobs = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Storage Accounts Public blobs",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureStorageAccountPublicBlobEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
