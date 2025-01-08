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


function Get-MonkeyAZClassicStorageAccount {
<#
        .SYNOPSIS
		Collector to get Classic Storage Account information from Azure

        .DESCRIPTION
		Collector to get Classic Storage Account information from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZClassicStorageAccount
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
			Id = "az00039";
			Provider = "Azure";
			Resource = "StorageAccounts";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZClassicStorageAccount";
			ApiType = "resourceManagement";
			description = "Collector to get Azure classic storage account infomration";
			Group = @(
				"StorageAccounts"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_classic_storage_accounts"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Service Management Auth
		$sm_auth = $O365Object.auth_tokens.ServiceManagement
		#Get Config
		$classicStorageConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureClassicStorage" } | Select-Object -ExpandProperty resource
		#Get from resources
		$storageAccounts = $O365Object.all_resources | Where-Object { $_.type -match 'Microsoft.ClassicStorage/storageAccounts' }
		if (-not $storageAccounts) { continue }
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure classic storage accounts",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureClassicStorageAccountInfo');
		}
		Write-Information @msg
		if ($storageAccounts) {
			#Create array
			$AllClassicStorageAccounts = @()
			#Get info for each storage account
			foreach ($str in $storageAccounts) {
				$URI = ("{0}{1}?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,$str.Id,`
 						$classicStorageConfig.api_version)
				#Launch query
				$params = @{
					Authentication = $sm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$storageAccount = Get-MonkeyRMObject @params
				#Get Data
				$new_str_account = New-Object -TypeName PSCustomObject
				$new_str_account | Add-Member -Type NoteProperty -Name id -Value $str.Id
				$new_str_account | Add-Member -Type NoteProperty -Name name -Value $str.Name
				$new_str_account | Add-Member -Type NoteProperty -Name location -Value $str.location
				$new_str_account | Add-Member -Type NoteProperty -Name properties -Value $str.Properties
				$new_str_account | Add-Member -Type NoteProperty -Name creationTime -Value $storageAccount.Properties.CreationTime
				$new_str_account | Add-Member -Type NoteProperty -Name accountType -Value $storageAccount.Properties.accountType
				$new_str_account | Add-Member -Type NoteProperty -Name geoPrimaryRegion -Value $storageAccount.Properties.geoPrimaryRegion
				$new_str_account | Add-Member -Type NoteProperty -Name statusOfPrimaryRegion -Value $storageAccount.Properties.statusOfPrimaryRegion
				$new_str_account | Add-Member -Type NoteProperty -Name geoSecondaryRegion -Value $storageAccount.Properties.geoSecondaryRegion
				$new_str_account | Add-Member -Type NoteProperty -Name statusOfSecondaryRegion -Value $storageAccount.Properties.statusOfSecondaryRegion
				$new_str_account | Add-Member -Type NoteProperty -Name provisioningState -Value $storageAccount.Properties.provisioningState
				$new_str_account | Add-Member -Type NoteProperty -Name rawObject -Value $storageAccount
				#Get Endpoints
				$queue = $storageAccount.Properties.endpoints | Where-Object { $_ -like "*queue*" }
				$table = $storageAccount.Properties.endpoints | Where-Object { $_ -like "*table*" }
				$file = $storageAccount.Properties.endpoints | Where-Object { $_ -like "*file*" }
				$blob = $storageAccount.Properties.endpoints | Where-Object { $_ -like "*blob*" }
				#Add to object
				$new_str_account | Add-Member -Type NoteProperty -Name queueEndpoint -Value $queue
				$new_str_account | Add-Member -Type NoteProperty -Name tableEndpoint -Value $table
				$new_str_account | Add-Member -Type NoteProperty -Name fileEndpoint -Value $file
				$new_str_account | Add-Member -Type NoteProperty -Name blobEndpoind -Value $blob
				#End endpoints
				$new_str_account | Add-Member -Type NoteProperty -Name status -Value $storageAccount.Properties.Status
				#Get Storage account keys
				$URI = ("{0}{1}/listKeys?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,$str.Id,`
 						$classicStorageConfig.api_version)
				$params = @{
					Authentication = $sm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Headers = @{ 'x-ms-version' = '2020-02-10' }
					Method = "POST";
				}
				$strkeys = Get-MonkeyRMObject @params
				if ($strkeys.primaryKey) {
					#Get Shared Access Signature
					$QueueSAS = Get-SASUri -HostName $queue -accessKey $strkeys.primaryKey
					if ($QueueSAS) {
						#Get Queue diagnostig settings
						$params = @{
							url = $QueueSAS;
							Method = "GET";
							UserAgent = $O365Object.UserAgent;
						}
						[xml]$QueueDiagSettings = Invoke-MonkeyWebRequest @params
						if ($QueueDiagSettings) {
							#Add to psobject
							$new_str_account | Add-Member -Type NoteProperty -Name queueLogVersion -Value $QueueDiagSettings.StorageServiceProperties.logging.Version
							$new_str_account | Add-Member -Type NoteProperty -Name queueLogReadEnabled -Value $QueueDiagSettings.StorageServiceProperties.logging.Read
							$new_str_account | Add-Member -Type NoteProperty -Name queueLogWriteEnabled -Value $QueueDiagSettings.StorageServiceProperties.logging.Write
							$new_str_account | Add-Member -Type NoteProperty -Name queueLogDeleteEnabled -Value $QueueDiagSettings.StorageServiceProperties.logging.Delete
							$new_str_account | Add-Member -Type NoteProperty -Name queueRetentionPolicyEnabled -Value $QueueDiagSettings.StorageServiceProperties.logging.retentionPolicy.enabled
							if ($QueueDiagSettings.StorageServiceProperties.logging.retentionPolicy.Days) {
								$new_str_account | Add-Member -Type NoteProperty -Name queueRetentionPolicyDays -Value $QueueDiagSettings.StorageServiceProperties.logging.retentionPolicy.Days
							}
							else {
								$new_str_account | Add-Member -Type NoteProperty -Name queueRetentionPolicyDays -Value $null
							}
						}
					}
					#Get Shared Access Signature
					$tableSAS = Get-SASUri -HostName $table -accessKey $strkeys.primaryKey
					if ($tableSAS) {
						#Get Queue diagnostig settings
						$params = @{
							url = $tableSAS;
							Method = "GET";
							UserAgent = $O365Object.UserAgent;
						}
						[xml]$TableDiagSettings = Invoke-MonkeyWebRequest @params
						if ($TableDiagSettings) {
							#Add to psobject
							$new_str_account | Add-Member -Type NoteProperty -Name tableLogVersion -Value $TableDiagSettings.StorageServiceProperties.logging.Version
							$new_str_account | Add-Member -Type NoteProperty -Name tableLogReadEnabled -Value $TableDiagSettings.StorageServiceProperties.logging.Read
							$new_str_account | Add-Member -Type NoteProperty -Name tableLogWriteEnabled -Value $TableDiagSettings.StorageServiceProperties.logging.Write
							$new_str_account | Add-Member -Type NoteProperty -Name tableLogDeleteEnabled -Value $TableDiagSettings.StorageServiceProperties.logging.Delete
							$new_str_account | Add-Member -Type NoteProperty -Name tableRetentionPolicyEnabled -Value $TableDiagSettings.StorageServiceProperties.logging.retentionPolicy.enabled
							if ($TableDiagSettings.StorageServiceProperties.logging.retentionPolicy.Days) {
								$new_str_account | Add-Member -Type NoteProperty -Name tableRetentionPolicyDays -Value $TableDiagSettings.StorageServiceProperties.logging.retentionPolicy.Days
							}
							else {
								$new_str_account | Add-Member -Type NoteProperty -Name tableRetentionPolicyDays -Value $null
							}
						}
					}
					#Get Shared Access Signature
					$fileSAS = Get-SASUri -HostName $file -accessKey $strkeys.primaryKey `

					if ($fileSAS) {
						#Get Queue diagnostig settings
						$params = @{
							url = $fileSAS;
							Method = "GET";
							UserAgent = $O365Object.UserAgent;
						}
						[xml]$FileDiagSettings = Invoke-MonkeyWebRequest @params
						if ($FileDiagSettings) {
							#Add to psobject
							$new_str_account | Add-Member -Type NoteProperty -Name fileHourMetricsVersion -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.Version
							$new_str_account | Add-Member -Type NoteProperty -Name fileHourMetricsEnabled -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.enabled
							$new_str_account | Add-Member -Type NoteProperty -Name fileHourMetricsIncludeAPIs -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.IncludeAPIs
							$new_str_account | Add-Member -Type NoteProperty -Name fileHourMetricsRetentionPolicyEnabled -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.retentionPolicy.enabled
							if ($FileDiagSettings.StorageServiceProperties.HourMetrics.retentionPolicy.Days) {
								$new_str_account | Add-Member -Type NoteProperty -Name fileHourMetricsRetentionPolicyDays -Value $FileDiagSettings.StorageServiceProperties.HourMetrics.retentionPolicy.Days
							}
							else {
								$new_str_account | Add-Member -Type NoteProperty -Name fileHourMetricsRetentionPolicyDays -Value $null
							}
							#Add to psobject
							$new_str_account | Add-Member -Type NoteProperty -Name fileMinuteMetricsVersion -Value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.Version
							$new_str_account | Add-Member -Type NoteProperty -Name fileMinuteMetricsEnabled -Value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.enabled
							$new_str_account | Add-Member -Type NoteProperty -Name fileMinuteMetricsRetentionPolicyEnabled -Value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.retentionPolicy.enabled
							if ($FileDiagSettings.StorageServiceProperties.MinuteMetrics.retentionPolicy.Days) {
								$new_str_account | Add-Member -Type NoteProperty -Name fileMinuteMetricsRetentionPolicyDays -Value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.retentionPolicy.Days
							}
							else {
								$new_str_account | Add-Member -Type NoteProperty -Name fileMinuteMetricsRetentionPolicyDays -Value $null
							}
						}
					}
					#Get Shared Access Signature
					$blobSAS = Get-SASUri -HostName $blob -accessKey $strkeys.primaryKey `

					if ($blobSAS) {
						#Get Blob diagnostig settings
						$params = @{
							url = $blobSAS;
							Method = "GET";
							UserAgent = $O365Object.UserAgent;
						}
						[xml]$BlobDiagSettings = Invoke-MonkeyWebRequest @params
						if ($BlobDiagSettings) {
							#Add to psobject
							$new_str_account | Add-Member -Type NoteProperty -Name blobLogVersion -Value $BlobDiagSettings.StorageServiceProperties.logging.Version
							$new_str_account | Add-Member -Type NoteProperty -Name blobLogReadEnabled -Value $BlobDiagSettings.StorageServiceProperties.logging.Read
							$new_str_account | Add-Member -Type NoteProperty -Name blobLogWriteEnabled -Value $BlobDiagSettings.StorageServiceProperties.logging.Write
							$new_str_account | Add-Member -Type NoteProperty -Name blobLogDeleteEnabled -Value $BlobDiagSettings.StorageServiceProperties.logging.Delete
							$new_str_account | Add-Member -Type NoteProperty -Name blobRetentionPolicyEnabled -Value $BlobDiagSettings.StorageServiceProperties.logging.retentionPolicy.enabled
							if ($BlobDiagSettings.StorageServiceProperties.logging.retentionPolicy.Days) {
								$new_str_account | Add-Member -Type NoteProperty -Name blobRetentionPolicyDays -Value $BlobDiagSettings.StorageServiceProperties.logging.retentionPolicy.Days
							}
							else {
								$new_str_account | Add-Member -Type NoteProperty -Name blobRetentionPolicyDays -Value $null
							}
						}
					}
				}
				#Add to array
				$AllClassicStorageAccounts += $new_str_account
			}
		}
		else {
			$msg = @{
				MessageData = ($message.NoClassicStorageAccounts -f $O365Object.current_subscription.displayName);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureClassicStorageAccountInfo');
			}
			Write-Warning @msg
			break;
		}
	}
	end {
		if ($AllClassicStorageAccounts) {
			$AllClassicStorageAccounts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ClassicStorageAccounts')
			[pscustomobject]$obj = @{
				Data = $AllClassicStorageAccounts;
				Metadata = $monkey_metadata;
			}
			$returnData.az_classic_storage_accounts = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Classic storage accounts",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureClassicStorageAccountEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









