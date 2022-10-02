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


function Get-MonkeyAzSQLDatabase {
<#
        .SYNOPSIS
		Plugin to get info about SQL Databases from Azure

        .DESCRIPTION
		Plugin to get info about SQL Databases from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSQLDatabase
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
			Id = "az00011";
			Provider = "AzureAD";
			Title = "Plugin to get info about SQL Databases from Azure";
			Group = @("Databases");
			ServiceName = "Azure SQL";
			PluginName = "Get-MonkeyAzSQLDatabase";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Config
		$AzureSQLConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForSQL" } | Select-Object -ExpandProperty resource
		#Get SQL Servers
		$DatabaseServers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Sql/servers' }
		if (-not $DatabaseServers) { continue }
		#Set arrays
		$AllDatabaseServers = @()
		$AllDatabases = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure SQL",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureSQLInfo');
		}
		Write-Information @msg
		if ($DatabaseServers) {
			foreach ($sql_server in $DatabaseServers) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $sql_server.Name,"SQL server");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureSQLServerInfo');
				}
				Write-Information @msg
				#Get Server
				$params = @{
					objectId = $sql_server.id;
					api_version = $AzureSQLConfig.api_version;
				}
				$server = Get-MonkeyRmObjectById @params
				#Get database info
				if ($server.Name -and $server.id) {
					$msg = @{
						MessageData = ($message.AzureDatabasesQueryMessage -f $server.Name);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureSQLDatabaseInfo');
					}
					Write-Information @msg
					$params = @{
						objectId = ($server.id).subString(1);
						api_version = $AzureSQLConfig.api_version;
						resource = "databases";
					}
					$Databases = Get-MonkeyRmObjectById @params
					#######Get Server Threat Detection Policy########
					$msg = @{
						MessageData = ($message.AzureDbThreatDetectionMessage -f $server.Name);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureSQLTDPInfo');
					}
					Write-Information @msg
					$params = @{
						objectId = ($server.id).subString(1);
						api_version = "2015-05-01-Preview";
						resource = "securityAlertPolicies/Default";
					}
					$ThreatDetectionPolicy = Get-MonkeyRmObjectById @params
					#######Get SQL Server Encryption Protector########
					$params = @{
						objectId = ($server.id).subString(1);
						api_version = "2015-05-01-Preview";
						resource = "encryptionProtector";
					}
					$ServerTDEProtectionSettings = Get-MonkeyRmObjectById @params
					#######Get SQL Server Vulnerability assessment config########
					$params = @{
						objectId = ($server.id).subString(1);
						api_version = "2018-06-01-preview";
						resource = "vulnerabilityAssessments/Default";
					}
					$sql_vulnerability_assessment_config = Get-MonkeyRmObjectById @params
					#######Get SQL Server Active Directory Administrator########
					$params = @{
						objectId = ($server.id).subString(1);
						api_version = "2014-04-01";
						resource = "administrators/activeDirectory";
					}
					$SQLServer_AD_Administrator = Get-MonkeyRmObjectById @params
					#######Get Server Auditing Policy########
					#https://www.mssqltips.com/sqlservertip/5180/azure-sql-database-auditing-using-blob-storage/
					$msg = @{
						MessageData = ($message.ServerAuditPolicyMessage -f $server.Name);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureSQLServerInfo');
					}
					Write-Information @msg

					$params = @{
						objectId = ($server.id).subString(1);
						api_version = "2015-05-01-Preview";
						resource = "auditingSettings/Default";
					}
					$ServerAuditingPolicy = Get-MonkeyRmObjectById @params
					#Add Server to Array
					$AzureSqlServer = New-Object -TypeName PSCustomObject
					$AzureSqlServer | Add-Member -Type NoteProperty -Name serverName -Value $server.Name
					$AzureSqlServer | Add-Member -Type NoteProperty -Name Id -Value $server.id
					$AzureSqlServer | Add-Member -Type NoteProperty -Name serverLocation -Value $server.location
					$AzureSqlServer | Add-Member -Type NoteProperty -Name serverKind -Value $server.kind
					$AzureSqlServer | Add-Member -Type NoteProperty -Name resourceGroupName -Value $server.id.Split("/")[4]
					$AzureSqlServer | Add-Member -Type NoteProperty -Name fullyQualifiedDomainName -Value $server.Properties.fullyQualifiedDomainName
					$AzureSqlServer | Add-Member -Type NoteProperty -Name administratorLogin -Value $server.Properties.administratorLogin
					$AzureSqlServer | Add-Member -Type NoteProperty -Name administratorLoginPassword -Value $server.Properties.administratorLoginPassword
					$AzureSqlServer | Add-Member -Type NoteProperty -Name externalAdministratorLogin -Value $server.Properties.externalAdministratorLogin
					$AzureSqlServer | Add-Member -Type NoteProperty -Name externalAdministratorSid -Value $server.Properties.externalAdministratorSid
					$AzureSqlServer | Add-Member -Type NoteProperty -Name version -Value $server.Properties.version
					$AzureSqlServer | Add-Member -Type NoteProperty -Name properties -Value $server.Properties
					$AzureSqlServer | Add-Member -Type NoteProperty -Name rawObject -Value $server
					$AzureSqlServer | Add-Member -Type NoteProperty -Name storageAccountAccessKey -Value $ServerAuditingPolicy.Properties.storageAccountAccessKey
					$AzureSqlServer | Add-Member -Type NoteProperty -Name auditingPolicyState -Value $ServerAuditingPolicy.Properties.state
					$AzureSqlServer | Add-Member -Type NoteProperty -Name auditActionsAndGroups -Value (@($ServerAuditingPolicy.Properties.auditActionsAndGroups) -join ',')
					$AzureSqlServer | Add-Member -Type NoteProperty -Name auditingRetentionDays -Value $ServerAuditingPolicy.Properties.retentionDays
					$AzureSqlServer | Add-Member -Type NoteProperty -Name isStorageSecondaryKeyInUse -Value $ServerAuditingPolicy.Properties.isStorageSecondaryKeyInUse
					$AzureSqlServer | Add-Member -Type NoteProperty -Name isAzureMonitorTargetEnabled -Value $ServerAuditingPolicy.Properties.isAzureMonitorTargetEnabled
					$AzureSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyRawObject -Value $ThreatDetectionPolicy
					$AzureSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicy -Value $ThreatDetectionPolicy.Properties.state
					$AzureSqlServer | Add-Member -Type NoteProperty -Name TDEProtectorMode -Value $ServerTDEProtectionSettings.kind
					$AzureSqlServer | Add-Member -Type NoteProperty -Name TDEProtectorServerkeyName -Value $ServerTDEProtectionSettings.Properties.serverKeyName
					$AzureSqlServer | Add-Member -Type NoteProperty -Name TDEProtectorServerkeyType -Value $ServerTDEProtectionSettings.Properties.serverKeyType
					$AzureSqlServer | Add-Member -Type NoteProperty -Name tdeRawObject -Value $ServerTDEProtectionSettings
					$AzureSqlServer | Add-Member -Type NoteProperty -Name vulnerabilityAssessmentConfig -Value $sql_vulnerability_assessment_config
					#Check for Encryption Protection URI
					if ($ServerTDEProtectionSettings.Properties.uri) {
						$AzureSqlServer | Add-Member -Type NoteProperty -Name TDEProtectorUri -Value $ServerTDEProtectionSettings.Properties.uri
					}
					else {
						$AzureSqlServer | Add-Member -Type NoteProperty -Name TDEProtectorUri -Value $null
					}
					#Check for disabled alerts
					if ($ThreatDetectionPolicy.Properties.disabledAlerts) {
						$AzureSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyDisabledAlerts -Value $ThreatDetectionPolicy.Properties.disabledAlerts
					}
					else {
						$AzureSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyDisabledAlerts -Value $false
					}
					if ($ThreatDetectionPolicy.Properties.emailAddresses) {
						$AzureSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAddresses -Value $ThreatDetectionPolicy.Properties.emailAddresses
					}
					else {
						$AzureSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAddresses -Value $null
					}
					$AzureSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAccountAdmins -Value $ThreatDetectionPolicy.Properties.emailAccountAdmins
					$AzureSqlServer | Add-Member -Type NoteProperty -Name threatDetectionPolicyRetentionDays -Value $ThreatDetectionPolicy.Properties.retentionDays
					if ($SQLServer_AD_Administrator) {
						$AzureSqlServer | Add-Member -Type NoteProperty -Name isSQLActiveDirectoryAdministratorEnabled -Value $true
						$AzureSqlServer | Add-Member -Type NoteProperty -Name sqlserveradministratorType -Value $SQLServer_AD_Administrator.Properties.administratorType
						$AzureSqlServer | Add-Member -Type NoteProperty -Name sqlserveradlogin -Value $SQLServer_AD_Administrator.Properties.login
						$AzureSqlServer | Add-Member -Type NoteProperty -Name sqlserveradloginsid -Value $SQLServer_AD_Administrator.Properties.sid
						$AzureSqlServer | Add-Member -Type NoteProperty -Name sqlserveradlogintenantid -Value $SQLServer_AD_Administrator.Properties.TenantID
					}
					else {
						$AzureSqlServer | Add-Member -Type NoteProperty -Name isSQLActiveDirectoryAdministratorEnabled -Value $false
					}
					#Add to list
					$AllDatabaseServers += $AzureSqlServer
					#Create object for each database found
					foreach ($sql in $Databases) {
						$AzureSql = New-Object -TypeName PSCustomObject
						$AzureSql | Add-Member -Type NoteProperty -Name serverName -Value $server.Name
						$AzureSql | Add-Member -Type NoteProperty -Name serverStatus -Value $server.Properties.state
						$AzureSql | Add-Member -Type NoteProperty -Name resourceGroupName -Value $server.id.Split("/")[4]
						$AzureSql | Add-Member -Type NoteProperty -Name databaseName -Value $sql.Name
						$AzureSql | Add-Member -Type NoteProperty -Name databaseLocation -Value $sql.location
						$AzureSql | Add-Member -Type NoteProperty -Name databaseStatus -Value $sql.Properties.status
						$AzureSql | Add-Member -Type NoteProperty -Name databaseEdition -Value $sql.Properties.edition
						$AzureSql | Add-Member -Type NoteProperty -Name properties -Value $sql.Properties
						$AzureSql | Add-Member -Type NoteProperty -Name rawObject -Value $sql
						$AzureSql | Add-Member -Type NoteProperty -Name serviceLevelObjective -Value $sql.Properties.serviceLevelObjective
						$AzureSql | Add-Member -Type NoteProperty -Name databaseCollation -Value $sql.Properties.collation
						$AzureSql | Add-Member -Type NoteProperty -Name databaseMaxSizeBytes -Value $sql.Properties.maxSizeBytes
						$AzureSql | Add-Member -Type NoteProperty -Name databaseCreationDate -Value $sql.Properties.creationDate
						$AzureSql | Add-Member -Type NoteProperty -Name databaseSampleName -Value $sql.Properties.sampleName
						$AzureSql | Add-Member -Type NoteProperty -Name databaseDefaultSecondaryLocation -Value $sql.Properties.defaultSecondaryLocation
						$AzureSql | Add-Member -Type NoteProperty -Name databaseReadScale -Value $sql.Properties.readScale
						if ($sql.Name -ne "master") {
							#######Get database Transparent Data Encryption Status########
							$msg = @{
								MessageData = ($message.DatabaseServerTDEMessage -f $sql.Name);
								callStack = (Get-PSCallStack | Select-Object -First 1);
								logLevel = 'info';
								InformationAction = $InformationAction;
								Tags = @('AzureSQLServerInfo');
							}
							Write-Information @msg
							$params = @{
								objectId = $sql.id;
								api_version = "2014-04-01";
								resource = "transparentDataEncryption/current";
							}
							$DTEPolicy = Get-MonkeyRmObjectById @params
							#Add to PSOBJECT
							$AzureSql | Add-Member -Type NoteProperty -Name databaseEncryptionStatus -Value $DTEPolicy.Properties.status
							$AzureSql | Add-Member -Type NoteProperty -Name dteRawObject -Value $DTEPolicy

							#######Get Database Auditing Policy########
							$params = @{
								objectId = $sql.id;
								api_version = "2015-05-01-preview";
								resource = "auditingSettings/Default";
							}
							$AuditingPolicy = Get-MonkeyRmObjectById @params
							#Add Auditing Policy for SQL database
							$AzureSql | Add-Member -Type NoteProperty -Name databaseAuditingState -Value $AuditingPolicy.Properties.state
							$AzureSql | Add-Member -Type NoteProperty -Name databaseAuditActionsAndGroups -Value (@($AuditingPolicy.Properties.auditActionsAndGroups) -join ',')
							$AzureSql | Add-Member -Type NoteProperty -Name databaseAuditStorageAccountAccessKey -Value $AuditingPolicy.Properties.storageAccountAccessKey
							if ($AuditingPolicy.Properties.storageEndpoint) {
								$AzureSql | Add-Member -Type NoteProperty -Name databaseAuditStorageAccountName -Value $AuditingPolicy.Properties.storageEndpoint.Split("/").Split(".")[2]
							}
							else {
								$AzureSql | Add-Member -Type NoteProperty -Name databaseAuditStorageAccountName -Value $null
							}
							$AzureSql | Add-Member -Type NoteProperty -Name databaseAuditRetentionDays -Value $AuditingPolicy.Properties.retentionDays
							#######Get Database Threat Detection Policy########
							$params = @{
								objectId = $sql.id;
								api_version = "2014-04-01";
								resource = "securityAlertPolicies/Default";
							}
							$DatabaseTDEPolicy = Get-MonkeyRmObjectById @params
							if ($DatabaseTDEPolicy) {
								$AzureSql | Add-Member -Type NoteProperty -Name threatDetectionPolicy -Value $DatabaseTDEPolicy.Properties.state
								$AzureSql | Add-Member -Type NoteProperty -Name threatDetectionPolicyDisabledAlerts -Value $DatabaseTDEPolicy.Properties.disabledAlerts
								$AzureSql | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAddresses -Value $DatabaseTDEPolicy.Properties.emailAddresses
								$AzureSql | Add-Member -Type NoteProperty -Name threatDetectionPolicyEmailAccountAdmins -Value $DatabaseTDEPolicy.Properties.emailAccountAdmins
								$AzureSql | Add-Member -Type NoteProperty -Name threatDetectionPolicyRetentionDays -Value $DatabaseTDEPolicy.Properties.retentionDays
								$AzureSql | Add-Member -Type NoteProperty -Name threatDetectionPolicyStorageAccountName -Value $DatabaseTDEPolicy.Properties.storageEndpoint.Split("/").Split(".")[2]
								$AzureSql | Add-Member -Type NoteProperty -Name tdpRawObject -Value $DatabaseTDEPolicy
							}
						}
						else {
							#Add to PSOBJECT
							#Database encryption operations cannot be performed for 'master', 'model', 'tempdb', 'msdb' or 'resource' databases.
							$AzureSql | Add-Member -Type NoteProperty -Name databaseEncryptionStatus -Value "None"
						}
						#Add to list
						$AllDatabases += $AzureSql
					}
				}
			}
		}
	}
	end {
		if ($AllDatabaseServers -and $AllDatabases) {
			$AllDatabaseServers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SQLServer')
			[pscustomobject]$obj = @{
				Data = $AllDatabaseServers;
				Metadata = $monkey_metadata;
			}
			$returnData.az_sql_servers = $obj
			#Add Servers to list
			$AllDatabases.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureSQLDatabases')
			[pscustomobject]$obj = @{
				Data = $AllDatabases;
				Metadata = $monkey_metadata;
			}
			$returnData.az_sql_databases = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure SQL",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureSQLEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
