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


function Get-MonkeyAzMysqlDatabase {
<#
        .SYNOPSIS
		Plugin to get about MySQL Databases from Azure

        .DESCRIPTION
		Plugin to get about MySQL Databases from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzMysqlDatabase
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
			Id = "az00009";
			Provider = "Azure";
			Title = "Plugin to get information about MySQL Databases from Azure";
			Group = @("Databases");
			ServiceName = "Azure MySQL databases";
			PluginName = "Get-MonkeyAzMysqlDatabase";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Config
		$AzureMySQLConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForMySQL" } | Select-Object -ExpandProperty resource
		#Get Mysql Servers
		$DatabaseServers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.DBforMySQL/servers' }
		if (-not $DatabaseServers) { continue }
		#Set arrays
		$AllMySQLServers = @()
		$AllMySQLDatabases = @()
		$AllMySQLServerConfigurations = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Mysql",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureMysqlInfo');
		}
		Write-Information @msg
		if ($DatabaseServers) {
			foreach ($mysql_server in $DatabaseServers) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $mysql_server.Name,"MySQL server");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureMysqlServerInfo');
				}
				Write-Information @msg
				#Construct URI
				$URI = ("{0}{1}?api-version={2}" `
 						-f $Environment.ResourceManager,`
 						$mysql_server.id,$AzureMySQLConfig.api_version)

				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$server = Get-MonkeyRMObject @params
				#Get database info
				if ($server.Name -and $server.id) {
					$msg = @{
						MessageData = ($message.AzureDatabasesQueryMessage -f $server.Name);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureMysqlDatabaseInfo');
					}
					Write-Information @msg
					$uri = ("{0}{1}/{2}?api-version={3}" -f $Environment.ResourceManager,`
 							($server.id).subString(1),"databases",`
 							$AzureMySQLConfig.api_version)
					#Get database info
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $uri;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$Databases = Get-MonkeyRMObject @params
					#######Get Server Threat Detection Policy########
					$msg = @{
						MessageData = ($message.AzureDbThreatDetectionMessage -f $server.Name);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureMysqlDatabaseInfo');
					}
					Write-Information @msg
					$uri = ("{0}{1}/{2}?api-version={3}" -f $Environment.ResourceManager,`
 							$server.id,`
 							"securityAlertPolicies/Default",`
 							$AzureMySQLConfig.api_version)

					#Get TDP info
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $uri;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$ThreatDetectionPolicy = Get-MonkeyRMObject @params
					#Get MySQL server Configuration
					$uri = ("{0}{1}/{2}?api-version={3}" -f $Environment.ResourceManager,`
 							$server.id,`
 							"configurations",`
 							$AzureMySQLConfig.api_version)

					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $uri;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$MySQLServerConfiguration = Get-MonkeyRMObject @params
					#Add Server to Array
					$AzureMySqlServer = New-Object -TypeName PSCustomObject
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name serverName -Value $server.Name
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name Id -Value $server.id
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name serverLocation -Value $server.location
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name resourceGroupName -Value $server.id.Split("/")[4]
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name fullyQualifiedDomainName -Value $server.Properties.fullyQualifiedDomainName
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name earliestRestoreDate -Value $server.Properties.earliestRestoreDate
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name sslEnforcement -Value $server.Properties.sslEnforcement
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name administratorLogin -Value $server.Properties.administratorLogin
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name userVisibleState -Value $server.Properties.userVisibleState
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name backupRetentionDays -Value $server.Properties.storageProfile.backupRetentionDays
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name geoRedundantBackup -Value $server.Properties.storageProfile.geoRedundantBackup
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name storageAutoGrow -Value $server.Properties.storageProfile.storageAutoGrow
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name replicationRole -Value $server.Properties.replicationRole
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name masterServerId -Value $server.Properties.masterServerId
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name version -Value $server.Properties.version
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name properties -Value $server.Properties
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name rawObject -Value $server
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicy -Value $ThreatDetectionPolicy.Properties.state
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyDisabledAlerts -Value (@($ThreatDetectionPolicy.Properties.disabledAlerts) -join ',')
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAddresses -Value (@($ThreatDetectionPolicy.Properties.emailAddresses) -join ',')
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAccountAdmins -Value $ThreatDetectionPolicy.Properties.emailAccountAdmins
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyRetentionDays -Value $ThreatDetectionPolicy.Properties.retentionDays
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyStorageEndpoint -Value $ThreatDetectionPolicy.Properties.storageEndpoint
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyStorageAccountAccessKey -Value $ThreatDetectionPolicy.Properties.storageAccountAccessKey
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyCreationTime -Value $ThreatDetectionPolicy.Properties.CreationTime
					$AzureMySqlServer | Add-Member -Type NoteProperty -Name tdpRawObject -Value $ThreatDetectionPolicy
					#Add to list
					$AllMySQLServers += $AzureMySqlServer
					#Create object for each database found
					foreach ($sql in $Databases) {
						$AzureMySQLDatabase = New-Object -TypeName PSCustomObject
						$AzureMySQLDatabase | Add-Member -Type NoteProperty -Name serverName -Value $server.Name
						$AzureMySQLDatabase | Add-Member -Type NoteProperty -Name databaseCharset -Value $server.Properties.charset
						$AzureMySQLDatabase | Add-Member -Type NoteProperty -Name resourceGroupName -Value $server.id.Split("/")[4]
						$AzureMySQLDatabase | Add-Member -Type NoteProperty -Name databaseName -Value $sql.Name
						$AzureMySQLDatabase | Add-Member -Type NoteProperty -Name databaseProperties -Value $sql.Properties
						$AzureMySQLDatabase | Add-Member -Type NoteProperty -Name databaseCollation -Value $sql.Properties.collation
						$AzureMySQLDatabase | Add-Member -Type NoteProperty -Name rawObject -Value $sql
						#Add to list
						$AllMySQLDatabases += $AzureMySQLDatabase
					}
					#Create object for each server configuration found
					foreach ($SingleConfiguration in $MySQLServerConfiguration) {
						$AzureMySQLServerConfiguration = New-Object -TypeName PSCustomObject
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name serverName -Value $server.Name
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterName -Value $SingleConfiguration.Name
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterDescription -Value $SingleConfiguration.Properties.description
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterValue -Value $SingleConfiguration.Properties.value
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterDefaultValue -Value $SingleConfiguration.Properties.defaultValue
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterDataType -Value $SingleConfiguration.Properties.dataType
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterSource -Value $SingleConfiguration.Properties.source
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterIsConfigPendingRestart -Value $SingleConfiguration.Properties.isConfigPendingRestart
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterIsDynamicConfig -Value $SingleConfiguration.Properties.isDynamicConfig
						$AzureMySQLServerConfiguration | Add-Member -Type NoteProperty -Name rawObject -Value $SingleConfiguration
						#Add to list
						$AllMySQLServerConfigurations += $AzureMySQLServerConfiguration
					}
				}
			}
		}
	}
	end {
		if ($AllMySQLServers) {
			$AllMySQLServers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureMySQLServer')
			[pscustomobject]$obj = @{
				Data = $AllMySQLServers;
				Metadata = $monkey_metadata;
			}
			$returnData.az_mysql_servers = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Mysql Server",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureMysqlEmptyResponse');
			}
			Write-Warning @msg
		}
		if ($AllMySQLDatabases) {
			#Add Databases to list
			$AllMySQLDatabases.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureMySQLDatabases')
			[pscustomobject]$obj = @{
				Data = $AllMySQLDatabases;
				Metadata = $monkey_metadata;
			}
			$returnData.az_mysql_databases = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Mysql databases",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureMysqlEmptyResponse');
			}
			Write-Warning @msg
		}
		if ($AllMySQLServerConfigurations) {
			#Add Server configuration to list
			$AllMySQLServerConfigurations.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureMySQLSingleConfiguration')
			[pscustomobject]$obj = @{
				Data = $AllMySQLServerConfigurations;
				Metadata = $monkey_metadata;
			}
			$returnData.az_mysql_configuration = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Mysql Configuration",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureMysqlEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
