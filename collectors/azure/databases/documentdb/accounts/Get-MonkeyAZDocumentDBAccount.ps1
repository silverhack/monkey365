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


function Get-MonkeyAZDocumentDBAccount {
<#
        .SYNOPSIS
		Azure DocumentDB

        .DESCRIPTION
		Azure DocumentDB

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZDocumentDBAccount
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
			Id = "az00012";
			Provider = "Azure";
			Resource = "Databases";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZDocumentDBAccount";
			ApiType = "resourceManagement";
			description = "Collector to get information about Azure DocumentDB";
			Group = @(
				"Databases"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_documentdb"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$AzureDocumentDB = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureDocumentDB" } | Select-Object -ExpandProperty resource
		#Get DocumentDB accounts
		$all_documentdb_accounts = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.DocumentDb/databaseAccounts' }
		if (-not $all_documentdb_accounts) { continue }
		#Create array
		$allDocumentDBAccounts = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure DocumentDB",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureDocumentDBInfo');
		}
		Write-Information @msg
		if ($all_documentdb_accounts) {
			foreach ($my_document_db in $all_documentdb_accounts) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $my_document_db.Name,"DocumentDB");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureDocumentDBServerInfo');
				}
				Write-Information @msg
				#Set query
				$p = @{
					Id = $my_document_db.Id;
					APIVersion = $AzureDocumentDB.api_version;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$document_db = Get-MonkeyAzObjectById @p
				if ($document_db.Id) {
					$msg = @{
						MessageData = ($message.AzureDatabasesQueryMessage -f $document_db.Name);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureDocumentDBServerInfo');
					}
					Write-Information @msg
					#get SQL Databases info
					$p = @{
						Id = $my_document_db.Id;
						Resource = 'sqlDatabases';
						APIVersion = $AzureDocumentDB.api_version;
						Verbose = $O365Object.Verbose;
						Debug = $O365Object.Debug;
						InformationAction = $O365Object.InformationAction;
					}
					$sql_databases = Get-MonkeyAzObjectById @p
					if ($sql_databases) {
						foreach ($database in $sql_databases) {
							$p = @{
								Id = $database.Id;
								Resource = 'containers';
								APIVersion = $AzureDocumentDB.api_version;
								Verbose = $O365Object.Verbose;
								Debug = $O365Object.Debug;
								InformationAction = $O365Object.InformationAction;
							}
							$containers = Get-MonkeyAzObjectById @p
							if ($containers) {
								$database | Add-Member -Type NoteProperty -Name containers -Value $containers
							}
						}
					}
					#add to documentDB
					$document_db | Add-Member -Type NoteProperty -Name sql_databases -Value $sql_databases
					#List keys for documentdb account
					$p = @{
						Id = $document_db.Id;
						Resource = 'listKeys';
						APIVersion = $AzureDocumentDB.api_version;
						Verbose = $O365Object.Verbose;
						Debug = $O365Object.Debug;
						InformationAction = $O365Object.InformationAction;
					}
					$keys = Get-MonkeyAzObjectById @p
					if ($keys) {
						#add keys to object
						$document_db | Add-Member -Type NoteProperty -Name keys -Value $keys
					}
					#add to array
					$allDocumentDBAccounts += $document_db
				}
			}
		}
	}
	end {
		if ($allDocumentDBAccounts) {
			$allDocumentDBAccounts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.DocumentDBAccounts')
			[pscustomobject]$obj = @{
				Data = $allDocumentDBAccounts;
				Metadata = $monkey_metadata;
			}
			$returnData.az_documentdb = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure DocumentDB",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureDocumentDBEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









