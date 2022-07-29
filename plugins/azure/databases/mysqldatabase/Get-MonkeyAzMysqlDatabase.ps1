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


Function Get-MonkeyAzMysqlDatabase{
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

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Config
        $AzureMySQLConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureForMySQL"} | Select-Object -ExpandProperty resource
        #Get Mysql Servers
        $DatabaseServers = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.DBforMySQL/servers'}
        if(-NOT $DatabaseServers){continue}
        #Set arrays
        $AllMySQLServers = @()
        $AllMySQLDatabases = @()
        $AllMySQLServerConfigurations = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Mysql", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureMysqlInfo');
        }
        Write-Information @msg
        if($DatabaseServers){
            foreach($mysql_server in $DatabaseServers){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $mysql_server.name, "MySQL server");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureMysqlServerInfo');
                }
                Write-Information @msg
                #Construct URI
                $URI = ("{0}{1}?api-version={2}" `
                        -f $Environment.ResourceManager, `
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
                if($server.name -AND $server.id){
                    $msg = @{
                        MessageData = ($message.AzureDatabasesQueryMessage -f $server.name);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $InformationAction;
                        Tags = @('AzureMysqlDatabaseInfo');
                    }
                    Write-Information @msg
                    $uri = ("{0}{1}/{2}?api-version={3}" -f $Environment.ResourceManager, `
                                                            ($server.id).subString(1), "databases", `
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
                        MessageData = ($message.AzureDbThreatDetectionMessage -f $server.name);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $InformationAction;
                        Tags = @('AzureMysqlDatabaseInfo');
                    }
                    Write-Information @msg
                    $uri = ("{0}{1}/{2}?api-version={3}" -f $Environment.ResourceManager, `
                                                            $server.id, `
                                                            "securityAlertPolicies/Default", `
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
                    $uri = ("{0}{1}/{2}?api-version={3}" -f $Environment.ResourceManager, `
                                                            $server.id, `
                                                            "configurations", `
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
                    $AzureMySqlServer | Add-Member -type NoteProperty -name serverName -value $server.name
                    $AzureMySqlServer | Add-Member -type NoteProperty -name Id -value $server.id
                    $AzureMySqlServer | Add-Member -type NoteProperty -name serverLocation -value $server.location
                    $AzureMySqlServer | Add-Member -type NoteProperty -name resourceGroupName -value $server.id.Split("/")[4]
                    $AzureMySqlServer | Add-Member -type NoteProperty -name fullyQualifiedDomainName -value $server.properties.fullyQualifiedDomainName
                    $AzureMySqlServer | Add-Member -type NoteProperty -name earliestRestoreDate -value $server.properties.earliestRestoreDate
                    $AzureMySqlServer | Add-Member -type NoteProperty -name sslEnforcement -value $server.properties.sslEnforcement
                    $AzureMySqlServer | Add-Member -type NoteProperty -name administratorLogin -value $server.properties.administratorLogin
                    $AzureMySqlServer | Add-Member -type NoteProperty -name userVisibleState -value $server.properties.userVisibleState
                    $AzureMySqlServer | Add-Member -type NoteProperty -name backupRetentionDays -value $server.properties.storageProfile.backupRetentionDays
                    $AzureMySqlServer | Add-Member -type NoteProperty -name geoRedundantBackup -value $server.properties.storageProfile.geoRedundantBackup
                    $AzureMySqlServer | Add-Member -type NoteProperty -name storageAutoGrow -value $server.properties.storageProfile.storageAutoGrow
                    $AzureMySqlServer | Add-Member -type NoteProperty -name replicationRole -value $server.properties.replicationRole
                    $AzureMySqlServer | Add-Member -type NoteProperty -name masterServerId -value $server.properties.masterServerId
                    $AzureMySqlServer | Add-Member -type NoteProperty -name version -value $server.properties.version
                    $AzureMySqlServer | Add-Member -type NoteProperty -name properties -value $server.properties
                    $AzureMySqlServer | Add-Member -type NoteProperty -name rawObject -value $server
                    $AzureMySqlServer | Add-Member -type NoteProperty -name threatDetectionPolicy -value $ThreatDetectionPolicy.properties.state
                    $AzureMySqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyDisabledAlerts -value (@($ThreatDetectionPolicy.properties.disabledAlerts) -join ',')
                    $AzureMySqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAddresses -value (@($ThreatDetectionPolicy.properties.emailAddresses) -join ',')
                    $AzureMySqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAccountAdmins -value $ThreatDetectionPolicy.properties.emailAccountAdmins
                    $AzureMySqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyRetentionDays -value $ThreatDetectionPolicy.properties.retentionDays
                    $AzureMySqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyStorageEndpoint -value $ThreatDetectionPolicy.properties.storageEndpoint
                    $AzureMySqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyStorageAccountAccessKey -value $ThreatDetectionPolicy.properties.storageAccountAccessKey
                    $AzureMySqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyCreationTime -value $ThreatDetectionPolicy.properties.creationTime
                    $AzureMySqlServer | Add-Member -type NoteProperty -name tdpRawObject -value $ThreatDetectionPolicy
                    #Add to list
                    $AllMySQLServers+=$AzureMySqlServer
                    #Create object for each database found
                    foreach ($sql in $Databases){
                        $AzureMySQLDatabase = New-Object -TypeName PSCustomObject
                        $AzureMySQLDatabase | Add-Member -type NoteProperty -name serverName -value $server.name
                        $AzureMySQLDatabase | Add-Member -type NoteProperty -name databaseCharset -value $server.properties.charset
                        $AzureMySQLDatabase | Add-Member -type NoteProperty -name resourceGroupName -value $server.id.Split("/")[4]
                        $AzureMySQLDatabase | Add-Member -type NoteProperty -name databaseName -value $sql.name
                        $AzureMySQLDatabase | Add-Member -type NoteProperty -name databaseProperties -value $sql.properties
                        $AzureMySQLDatabase | Add-Member -type NoteProperty -name databaseCollation -value $sql.properties.collation
                        $AzureMySQLDatabase | Add-Member -type NoteProperty -name rawObject -value $sql
                        #Add to list
                        $AllMySQLDatabases+=$AzureMySQLDatabase
                    }
                    #Create object for each server configuration found
                    foreach ($SingleConfiguration in $MySQLServerConfiguration){
                        $AzureMySQLServerConfiguration = New-Object -TypeName PSCustomObject
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name serverName -value $server.name
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name parameterName -value $SingleConfiguration.name
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name parameterDescription -value $SingleConfiguration.properties.description
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name parameterValue -value $SingleConfiguration.properties.value
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name parameterDefaultValue -value $SingleConfiguration.properties.defaultValue
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name parameterDataType -value $SingleConfiguration.properties.dataType
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name parameterSource -value $SingleConfiguration.properties.source
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name parameterIsConfigPendingRestart -value $SingleConfiguration.properties.isConfigPendingRestart
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name parameterIsDynamicConfig -value $SingleConfiguration.properties.isDynamicConfig
                        $AzureMySQLServerConfiguration | Add-Member -type NoteProperty -name rawObject -value $SingleConfiguration
                        #Add to list
                        $AllMySQLServerConfigurations+=$AzureMySQLServerConfiguration
                    }
                }
            }
        }
    }
    End{
        if($AllMySQLServers){
            $AllMySQLServers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureMySQLServer')
            [pscustomobject]$obj = @{
                Data = $AllMySQLServers
            }
            $returnData.az_mysql_servers = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Mysql Server", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureMysqlEmptyResponse');
            }
            Write-Warning @msg
        }
        if($AllMySQLDatabases){
            #Add Databases to list
            $AllMySQLDatabases.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureMySQLDatabases')
            [pscustomobject]$obj = @{
                Data = $AllMySQLDatabases
            }
            $returnData.az_mysql_databases = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Mysql databases", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureMysqlEmptyResponse');
            }
            Write-Warning @msg
        }
        if($AllMySQLServerConfigurations){
            #Add Server configuration to list
            $AllMySQLServerConfigurations.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureMySQLSingleConfiguration')
            [pscustomobject]$obj = @{
                Data = $AllMySQLServerConfigurations
            }
            $returnData.az_mysql_configuration = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Mysql Configuration", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureMysqlEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
