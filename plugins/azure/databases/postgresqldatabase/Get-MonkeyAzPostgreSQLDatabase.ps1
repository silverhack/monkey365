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


function Get-MonkeyAzPostgreSQLDatabase {
<#
        .SYNOPSIS
		Plugin to get info about PostgreSQL Databases from Azure

        .DESCRIPTION
		Plugin to get info about PostgreSQL Databases from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzPostgreSQLDatabase
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
			Id = "az00010";
			Provider = "Azure";
			Title = "Plugin to get info about PostgreSQL Databases from Azure";
			Group = @("Databases");
			ServiceName = "Azure PostgreSQL";
			PluginName = "Get-MonkeyAzPostgreSQLDatabase";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Config
		$AzurePostgreSQLConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForPostgreSQL" } | Select-Object -ExpandProperty resource
		#Get PostgreSQL Servers
		$DatabaseServers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.DBforPostgreSQL/servers' }
		if (-not $DatabaseServers) { continue }
		#Set arrays
		$AllPostgreSQLServers = @()
		$AllPostgreSQLDatabases = @()
		$AllPostgreSQLServerConfigurations = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure PostgreSQL",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePostgreSQLInfo');
		}
		Write-Information @msg
		if ($DatabaseServers) {
			foreach ($postgre_server in $DatabaseServers) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $postgre_server.Name,"PostgreSQL server");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzurePostgreSQLServerInfo');
				}
				Write-Information @msg
				#Construct URI
				$URI = ("{0}{1}?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,`
 						$postgre_server.id,$AzurePostgreSQLConfig.api_version)

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
						Tags = @('AzurePostgreSQLDatabaseInfo');
					}
					Write-Information @msg
					$uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,`
 							($server.id).subString(1),"databases",`
 							$AzurePostgreSQLConfig.api_version)

					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $URI;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$Databases = Get-MonkeyRMObject @params
					#Get PostgreSQL server Configuration
					$uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,`
 							$server.id,`
 							"configurations",`
 							$AzurePostgreSQLConfig.api_version)

					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $uri;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$PostgreSQLServerConfiguration = Get-MonkeyRMObject @params
					#Get PostgreSQL Active Directory Admin configuration
					$uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,`
 							$server.id,`
 							"administrators/activeDirectory",`
 							$AzurePostgreSQLConfig.api_version)

					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $uri;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$PSQLServer_AD_Administrator = Get-MonkeyRMObject @params
					#Add Server to Array
					$AzurePostgreSqlServer = New-Object -TypeName PSCustomObject
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name serverName -Value $server.Name
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name Id -Value $server.id
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name serverLocation -Value $server.location
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name resourceGroupName -Value $server.id.Split("/")[4]
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name fullyQualifiedDomainName -Value $server.Properties.fullyQualifiedDomainName
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name earliestRestoreDate -Value $server.Properties.earliestRestoreDate
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name sslEnforcement -Value $server.Properties.sslEnforcement
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name administratorLogin -Value $server.Properties.administratorLogin
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name userVisibleState -Value $server.Properties.userVisibleState
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name backupRetentionDays -Value $server.Properties.storageProfile.backupRetentionDays
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name geoRedundantBackup -Value $server.Properties.storageProfile.geoRedundantBackup
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name version -Value $server.Properties.version
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name properties -Value $server.Properties
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name rawObject -Value $server
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicy -Value $ThreatDetectionPolicy.Properties.state
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyDisabledAlerts -Value $ThreatDetectionPolicy.Properties.disabledAlerts
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAddresses -Value $ThreatDetectionPolicy.Properties.emailAddresses
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAccountAdmins -Value $ThreatDetectionPolicy.Properties.emailAccountAdmins
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyRetentionDays -Value $ThreatDetectionPolicy.Properties.retentionDays
					$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name tdpRawObject -Value $ThreatDetectionPolicy
					if ($PSQLServer_AD_Administrator) {
						$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name isActiveDirectoryAdministratorEnabled -Value $true
						$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name psqlserveradministratorType -Value $PSQLServer_AD_Administrator.Properties.administratorType
						$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name psqlserveradlogin -Value $PSQLServer_AD_Administrator.Properties.login
						$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name psqlserveradloginsid -Value $PSQLServer_AD_Administrator.Properties.sid
						$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name psqlserveradlogintenantid -Value $PSQLServer_AD_Administrator.Properties.TenantID
					}
					else {
						$AzurePostgreSqlServer | Add-Member -Type NoteProperty -Name isActiveDirectoryAdministratorEnabled -Value $false
					}
					#Add to list
					$AllPostgreSQLServers += $AzurePostgreSqlServer
					#Create object for each database found
					foreach ($sql in $Databases) {
						$AzurePostgreSQLDatabase = New-Object -TypeName PSCustomObject
						$AzurePostgreSQLDatabase | Add-Member -Type NoteProperty -Name serverName -Value $server.Name
						$AzurePostgreSQLDatabase | Add-Member -Type NoteProperty -Name databaseCharset -Value $server.Properties.charset
						$AzurePostgreSQLDatabase | Add-Member -Type NoteProperty -Name resourceGroupName -Value $server.id.Split("/")[4]
						$AzurePostgreSQLDatabase | Add-Member -Type NoteProperty -Name databaseName -Value $sql.Name
						$AzurePostgreSQLDatabase | Add-Member -Type NoteProperty -Name databaseCollation -Value $sql.Properties.collation
						$AzurePostgreSQLDatabase | Add-Member -Type NoteProperty -Name properties -Value $sql.Properties
						$AzurePostgreSQLDatabase | Add-Member -Type NoteProperty -Name rawObject -Value $sql
						#Add to list
						$AllPostgreSQLDatabases += $AzurePostgreSQLDatabase
					}
					#Create object for each server configuration found
					foreach ($SingleConfiguration in $PostgreSQLServerConfiguration) {
						$AzurePostgreSQLServerConfiguration = New-Object -TypeName PSCustomObject
						$AzurePostgreSQLServerConfiguration | Add-Member -Type NoteProperty -Name serverName -Value $server.Name
						$AzurePostgreSQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterName -Value $SingleConfiguration.Name
						$AzurePostgreSQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterDescription -Value $SingleConfiguration.Properties.description
						$AzurePostgreSQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterValue -Value $SingleConfiguration.Properties.value
						$AzurePostgreSQLServerConfiguration | Add-Member -Type NoteProperty -Name parameterDefaultValue -Value $SingleConfiguration.Properties.defaultValue
						$AzurePostgreSQLServerConfiguration | Add-Member -Type NoteProperty -Name properties -Value $SingleConfiguration.Properties
						$AzurePostgreSQLServerConfiguration | Add-Member -Type NoteProperty -Name rawObject -Value $SingleConfiguration
						#Add to list
						$AllPostgreSQLServerConfigurations += $AzurePostgreSQLServerConfiguration
					}
				}
			}
		}
	}
	end {
		if ($AllPostgreSQLServers) {
			$AllPostgreSQLServers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzurePostgreSQLServer')
			[pscustomobject]$obj = @{
				Data = $AllPostgreSQLServers;
				Metadata = $monkey_metadata;
			}
			$returnData.az_postgresql_servers = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PostgreSQL Server",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePostgreSQLEmptyResponse');
			}
			Write-Warning @msg
		}
		if ($AllPostgreSQLDatabases) {
			#Add Databases to list
			$AllPostgreSQLDatabases.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzurePostgreSQLDatabases')
			[pscustomobject]$obj = @{
				Data = $AllPostgreSQLDatabases;
				Metadata = $monkey_metadata;
			}
			$returnData.az_postgresql_databases = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PostgreSQL Databases",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePostgreSQLEmptyResponse');
			}
			Write-Warning @msg
		}
		if ($AllPostgreSQLServerConfigurations) {
			#Add Server configuration to list
			$AllPostgreSQLServerConfigurations.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzurePostgreSQLSingleConfiguration')
			[pscustomobject]$obj = @{
				Data = $AllPostgreSQLServerConfigurations;
				Metadata = $monkey_metadata;
			}
			$returnData.az_postgresql_configuration = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PostgreSQL Configurations",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePostgreSQLEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
