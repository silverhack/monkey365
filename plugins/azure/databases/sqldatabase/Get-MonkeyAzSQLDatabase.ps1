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


Function Get-MonkeyAzSQLDatabase{
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

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Config
        $AzureSQLConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureForSQL"} | Select-Object -ExpandProperty resource
        #Get SQL Servers
        $DatabaseServers = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Sql/servers'}
        if(-NOT $DatabaseServers){continue}
        #Set arrays
        $AllDatabaseServers = @()
        $AllDatabases = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure SQL", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureSQLInfo');
        }
        Write-Information @msg
        if($DatabaseServers){
            foreach($sql_server in $DatabaseServers){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $sql_server.name, "SQL server");
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
                if($server.name -AND $server.id){
                    $msg = @{
                        MessageData = ($message.AzureDatabasesQueryMessage -f $server.name);
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
                        MessageData = ($message.AzureDbThreatDetectionMessage -f $server.name);
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
                        MessageData = ($message.ServerAuditPolicyMessage -f $server.name);
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
                    $AzureSqlServer | Add-Member -type NoteProperty -name serverName -value $server.name
                    $AzureSqlServer | Add-Member -type NoteProperty -name Id -value $server.id
                    $AzureSqlServer | Add-Member -type NoteProperty -name serverLocation -value $server.location
                    $AzureSqlServer | Add-Member -type NoteProperty -name serverKind -value $server.kind
                    $AzureSqlServer | Add-Member -type NoteProperty -name resourceGroupName -value $server.id.Split("/")[4]
                    $AzureSqlServer | Add-Member -type NoteProperty -name fullyQualifiedDomainName -value $server.properties.fullyQualifiedDomainName
                    $AzureSqlServer | Add-Member -type NoteProperty -name administratorLogin -value $server.properties.administratorLogin
                    $AzureSqlServer | Add-Member -type NoteProperty -name administratorLoginPassword -value $server.properties.administratorLoginPassword
                    $AzureSqlServer | Add-Member -type NoteProperty -name externalAdministratorLogin -value $server.properties.externalAdministratorLogin
                    $AzureSqlServer | Add-Member -type NoteProperty -name externalAdministratorSid -value $server.properties.externalAdministratorSid
                    $AzureSqlServer | Add-Member -type NoteProperty -name version -value $server.properties.version
                    $AzureSqlServer | Add-Member -type NoteProperty -name properties -value $server.properties
                    $AzureSqlServer | Add-Member -type NoteProperty -name rawObject -value $server
                    $AzureSqlServer | Add-Member -type NoteProperty -name storageAccountAccessKey -value $ServerAuditingPolicy.properties.storageAccountAccessKey
                    $AzureSqlServer | Add-Member -type NoteProperty -name auditingPolicyState -value $ServerAuditingPolicy.properties.state
                    $AzureSqlServer | Add-Member -type NoteProperty -name auditActionsAndGroups -value (@($ServerAuditingPolicy.properties.auditActionsAndGroups) -join ',')
                    $AzureSqlServer | Add-Member -type NoteProperty -name auditingRetentionDays -value $ServerAuditingPolicy.properties.retentionDays
                    $AzureSqlServer | Add-Member -type NoteProperty -name isStorageSecondaryKeyInUse -value $ServerAuditingPolicy.properties.isStorageSecondaryKeyInUse
                    $AzureSqlServer | Add-Member -type NoteProperty -name isAzureMonitorTargetEnabled -value $ServerAuditingPolicy.properties.isAzureMonitorTargetEnabled
                    $AzureSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyRawObject -value $ThreatDetectionPolicy
                    $AzureSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicy -value $ThreatDetectionPolicy.properties.state
                    $AzureSqlServer | Add-Member -type NoteProperty -name TDEProtectorMode -value $ServerTDEProtectionSettings.kind
                    $AzureSqlServer | Add-Member -type NoteProperty -name TDEProtectorServerkeyName -value $ServerTDEProtectionSettings.properties.serverKeyName
                    $AzureSqlServer | Add-Member -type NoteProperty -name TDEProtectorServerkeyType -value $ServerTDEProtectionSettings.properties.serverKeyType
                    $AzureSqlServer | Add-Member -type NoteProperty -name tdeRawObject -value $ServerTDEProtectionSettings
                    $AzureSqlServer | Add-Member -type NoteProperty -name vulnerabilityAssessmentConfig -value $sql_vulnerability_assessment_config
                    #Check for Encryption Protection URI
                    if($ServerTDEProtectionSettings.properties.uri){
                        $AzureSqlServer | Add-Member -type NoteProperty -name TDEProtectorUri -value $ServerTDEProtectionSettings.properties.uri
                    }
                    else{
                        $AzureSqlServer | Add-Member -type NoteProperty -name TDEProtectorUri -value $null
                    }
                    #Check for disabled alerts
                    if($ThreatDetectionPolicy.properties.disabledAlerts){
                        $AzureSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyDisabledAlerts -value $ThreatDetectionPolicy.properties.disabledAlerts
                    }
                    else{
                        $AzureSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyDisabledAlerts -value $false
                    }
                    if($ThreatDetectionPolicy.properties.emailAddresses){
                        $AzureSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAddresses -value $ThreatDetectionPolicy.properties.emailAddresses
                    }
                    else{
                        $AzureSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAddresses -value $null
                    }
                    $AzureSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAccountAdmins -value $ThreatDetectionPolicy.properties.emailAccountAdmins
                    $AzureSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyRetentionDays -value $ThreatDetectionPolicy.properties.retentionDays
                    if($SQLServer_AD_Administrator){
                        $AzureSqlServer | Add-Member -type NoteProperty -name isSQLActiveDirectoryAdministratorEnabled -value $true
                        $AzureSqlServer | Add-Member -type NoteProperty -name sqlserveradministratorType -value $SQLServer_AD_Administrator.properties.administratorType
                        $AzureSqlServer | Add-Member -type NoteProperty -name sqlserveradlogin -value $SQLServer_AD_Administrator.properties.login
                        $AzureSqlServer | Add-Member -type NoteProperty -name sqlserveradloginsid -value $SQLServer_AD_Administrator.properties.sid
                        $AzureSqlServer | Add-Member -type NoteProperty -name sqlserveradlogintenantid -value $SQLServer_AD_Administrator.properties.tenantId
                    }
                    else{
                        $AzureSqlServer | Add-Member -type NoteProperty -name isSQLActiveDirectoryAdministratorEnabled -value $false
                    }
                    #Add to list
                    $AllDatabaseServers+=$AzureSqlServer
                    #Create object for each database found
                    foreach ($sql in $Databases){
                        $AzureSql = New-Object -TypeName PSCustomObject
                        $AzureSql | Add-Member -type NoteProperty -name serverName -value $server.name
                        $AzureSql | Add-Member -type NoteProperty -name serverStatus -value $server.properties.state
                        $AzureSql | Add-Member -type NoteProperty -name resourceGroupName -value $server.id.Split("/")[4]
                        $AzureSql | Add-Member -type NoteProperty -name databaseName -value $sql.name
                        $AzureSql | Add-Member -type NoteProperty -name databaseLocation -value $sql.location
                        $AzureSql | Add-Member -type NoteProperty -name databaseStatus -value $sql.properties.status
                        $AzureSql | Add-Member -type NoteProperty -name databaseEdition -value $sql.properties.edition
                        $AzureSql | Add-Member -type NoteProperty -name properties -value $sql.properties
                        $AzureSql | Add-Member -type NoteProperty -name rawObject -value $sql
                        $AzureSql | Add-Member -type NoteProperty -name serviceLevelObjective -value $sql.properties.serviceLevelObjective
                        $AzureSql | Add-Member -type NoteProperty -name databaseCollation -value $sql.properties.collation
                        $AzureSql | Add-Member -type NoteProperty -name databaseMaxSizeBytes -value $sql.properties.maxSizeBytes
                        $AzureSql | Add-Member -type NoteProperty -name databaseCreationDate -value $sql.properties.creationDate
                        $AzureSql | Add-Member -type NoteProperty -name databaseSampleName -value $sql.properties.sampleName
                        $AzureSql | Add-Member -type NoteProperty -name databaseDefaultSecondaryLocation -value $sql.properties.defaultSecondaryLocation
                        $AzureSql | Add-Member -type NoteProperty -name databaseReadScale -value $sql.properties.readScale
                        if ($sql.name -ne "master"){
                            #######Get database Transparent Data Encryption Status########
                            $msg = @{
                                MessageData = ($message.DatabaseServerTDEMessage -f $sql.name);
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
                            $AzureSql | Add-Member -type NoteProperty -name databaseEncryptionStatus -value $DTEPolicy.properties.status
                            $AzureSql | Add-Member -type NoteProperty -name dteRawObject -value $DTEPolicy

                            #######Get Database Auditing Policy########
                            $params = @{
                                objectId = $sql.id;
                                api_version = "2015-05-01-preview";
                                resource = "auditingSettings/Default";
                            }
                            $AuditingPolicy = Get-MonkeyRmObjectById @params
                            #Add Auditing Policy for SQL database
                            $AzureSql | Add-Member -type NoteProperty -name databaseAuditingState -value $AuditingPolicy.properties.state
                            $AzureSql | Add-Member -type NoteProperty -name databaseAuditActionsAndGroups -value (@($AuditingPolicy.properties.auditActionsAndGroups) -join ',')
                            $AzureSql | Add-Member -type NoteProperty -name databaseAuditStorageAccountAccessKey -value $AuditingPolicy.properties.storageAccountAccessKey
                            if($AuditingPolicy.properties.storageEndpoint){
                                $AzureSql | Add-Member -type NoteProperty -name databaseAuditStorageAccountName -value $AuditingPolicy.properties.storageEndpoint.Split("/").split(".")[2]
                            }
                            else{
                                $AzureSql | Add-Member -type NoteProperty -name databaseAuditStorageAccountName -value $null
                            }
                            $AzureSql | Add-Member -type NoteProperty -name databaseAuditRetentionDays -value $AuditingPolicy.properties.retentionDays
                            #######Get Database Threat Detection Policy########
                            $params = @{
                                objectId = $sql.id;
                                api_version = "2014-04-01";
                                resource = "securityAlertPolicies/Default";
                            }
                            $DatabaseTDEPolicy = Get-MonkeyRmObjectById @params
                            if($DatabaseTDEPolicy){
                                $AzureSql | Add-Member -type NoteProperty -name threatDetectionPolicy -value $DatabaseTDEPolicy.properties.state
                                $AzureSql | Add-Member -type NoteProperty -name threatDetectionPolicyDisabledAlerts -value $DatabaseTDEPolicy.properties.disabledAlerts
                                $AzureSql | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAddresses -value $DatabaseTDEPolicy.properties.emailAddresses
                                $AzureSql | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAccountAdmins -value $DatabaseTDEPolicy.properties.emailAccountAdmins
                                $AzureSql | Add-Member -type NoteProperty -name threatDetectionPolicyRetentionDays -value $DatabaseTDEPolicy.properties.retentionDays
                                $AzureSql | Add-Member -type NoteProperty -name threatDetectionPolicyStorageAccountName -value $DatabaseTDEPolicy.properties.storageEndpoint.Split("/").split(".")[2]
                                $AzureSql | Add-Member -type NoteProperty -name tdpRawObject -value $DatabaseTDEPolicy
                            }
                        }
                        else{
                            #Add to PSOBJECT
                            #Database encryption operations cannot be performed for 'master', 'model', 'tempdb', 'msdb' or 'resource' databases.
                            $AzureSql | Add-Member -type NoteProperty -name databaseEncryptionStatus -value "None"
                        }
                        #Add to list
                        $AllDatabases+=$AzureSql
                    }
                }
            }
        }
    }
    End{
        if($AllDatabaseServers -AND $AllDatabases){
            $AllDatabaseServers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SQLServer')
            [pscustomobject]$obj = @{
                Data = $AllDatabaseServers
            }
            $returnData.az_sql_servers = $obj
            #Add Servers to list
            $AllDatabases.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureSQLDatabases')
            [pscustomobject]$obj = @{
                Data = $AllDatabases
            }
            $returnData.az_sql_databases = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure SQL", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureSQLEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
