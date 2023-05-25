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
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00012";
			Provider = "Azure";
			Resource = "Databases";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAZDocumentDBAccount";
			ApiType = "resourceManagement";
			Title = "Plugin to get information about Azure DocumentDB";
			Group = @("Databases");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
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
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure DocumentDB",$O365Object.current_subscription.displayName);
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
				#Construct URI
				$URI = ("{0}{1}?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,`
 						$my_document_db.Id,$AzureDocumentDB.api_version)
				#launch request
				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$document_db = Get-MonkeyRMObject @params
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
					$URI = ('{0}{1}/sqlDatabases?api-version={2}' -f $O365Object.Environment.ResourceManager,`
 							$my_document_db.Id,`
 							$AzureDocumentDB.api_version)
					#Perform Query
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $URI;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$sql_databases = Get-MonkeyRMObject @params
					if ($sql_databases) {
						foreach ($database in $sql_databases) {
							#Get containers info
							$URI = ('{0}{1}/containers?api-version={2}' -f $O365Object.Environment.ResourceManager,`
 									$database.Id,`
 									$AzureDocumentDB.api_version)
							#Launch Query
							$params = @{
								Authentication = $rm_auth;
								OwnQuery = $URI;
								Environment = $Environment;
								ContentType = 'application/json';
								Method = "GET";
							}
							$containers = Get-MonkeyRMObject @params
							if ($containers) {
								$database | Add-Member -Type NoteProperty -Name containers -Value $containers
							}
						}
					}
					#add to documentDB
					$document_db | Add-Member -Type NoteProperty -Name sql_databases -Value $sql_databases
					#List keys for documentdb account
					$URI = ('{0}{1}/listKeys?api-version={2}' -f $O365Object.Environment.ResourceManager,`
 							$document_db.Id,`
 							$AzureDocumentDB.api_version)
					#Perform Query
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $URI;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "POST";
					}
					$keys = Get-MonkeyRMObject @params
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




