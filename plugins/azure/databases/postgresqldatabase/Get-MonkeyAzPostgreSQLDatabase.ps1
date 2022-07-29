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


Function Get-MonkeyAzPostgreSQLDatabase{
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
        $AzurePostgreSQLConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureForPostgreSQL"} | Select-Object -ExpandProperty resource
        #Get PostgreSQL Servers
        $DatabaseServers = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.DBforPostgreSQL/servers'}
        if(-NOT $DatabaseServers){continue}
        #Set arrays
        $AllPostgreSQLServers = @()
        $AllPostgreSQLDatabases = @()
        $AllPostgreSQLServerConfigurations = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure PostgreSQL", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzurePostgreSQLInfo');
        }
        Write-Information @msg
        if($DatabaseServers){
            foreach($postgre_server in $DatabaseServers){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $postgre_server.name, "PostgreSQL server");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzurePostgreSQLServerInfo');
                }
                Write-Information @msg
                #Construct URI
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager, `
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
                if($server.name -AND $server.id){
                    $msg = @{
                        MessageData = ($message.AzureDatabasesQueryMessage -f $server.name);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $InformationAction;
                        Tags = @('AzurePostgreSQLDatabaseInfo');
                    }
                    Write-Information @msg
                    $uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, `
                                                            ($server.id).subString(1), "databases", `
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
                    $uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, `
                                                            $server.id, `
                                                            "configurations", `
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
                    $uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, `
                                                            $server.id, `
                                                            "administrators/activeDirectory", `
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
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name serverName -value $server.name
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name Id -value $server.id
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name serverLocation -value $server.location
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name resourceGroupName -value $server.id.Split("/")[4]
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name fullyQualifiedDomainName -value $server.properties.fullyQualifiedDomainName
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name earliestRestoreDate -value $server.properties.earliestRestoreDate
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name sslEnforcement -value $server.properties.sslEnforcement
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name administratorLogin -value $server.properties.administratorLogin
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name userVisibleState -value $server.properties.userVisibleState
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name backupRetentionDays -value $server.properties.storageProfile.backupRetentionDays
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name geoRedundantBackup -value $server.properties.storageProfile.geoRedundantBackup
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name version -value $server.properties.version
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name properties -value $server.properties
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name rawObject -value $server
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicy -value $ThreatDetectionPolicy.properties.state
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyDisabledAlerts -value $ThreatDetectionPolicy.properties.disabledAlerts
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAddresses -value $ThreatDetectionPolicy.properties.emailAddresses
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyEmailAccountAdmins -value $ThreatDetectionPolicy.properties.emailAccountAdmins
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name threatDetectionPolicyRetentionDays -value $ThreatDetectionPolicy.properties.retentionDays
                    $AzurePostgreSqlServer | Add-Member -type NoteProperty -name tdpRawObject -value $ThreatDetectionPolicy
                    if($PSQLServer_AD_Administrator){
                        $AzurePostgreSqlServer | Add-Member -type NoteProperty -name isActiveDirectoryAdministratorEnabled -value $true
                        $AzurePostgreSqlServer | Add-Member -type NoteProperty -name psqlserveradministratorType -value $PSQLServer_AD_Administrator.properties.administratorType
                        $AzurePostgreSqlServer | Add-Member -type NoteProperty -name psqlserveradlogin -value $PSQLServer_AD_Administrator.properties.login
                        $AzurePostgreSqlServer | Add-Member -type NoteProperty -name psqlserveradloginsid -value $PSQLServer_AD_Administrator.properties.sid
                        $AzurePostgreSqlServer | Add-Member -type NoteProperty -name psqlserveradlogintenantid -value $PSQLServer_AD_Administrator.properties.tenantId
                    }
                    else{
                        $AzurePostgreSqlServer | Add-Member -type NoteProperty -name isActiveDirectoryAdministratorEnabled -value $false
                    }
                    #Add to list
                    $AllPostgreSQLServers+=$AzurePostgreSqlServer
                    #Create object for each database found
                    foreach ($sql in $Databases){
                        $AzurePostgreSQLDatabase = New-Object -TypeName PSCustomObject
                        $AzurePostgreSQLDatabase | Add-Member -type NoteProperty -name serverName -value $server.name
                        $AzurePostgreSQLDatabase | Add-Member -type NoteProperty -name databaseCharset -value $server.properties.charset
                        $AzurePostgreSQLDatabase | Add-Member -type NoteProperty -name resourceGroupName -value $server.id.Split("/")[4]
                        $AzurePostgreSQLDatabase | Add-Member -type NoteProperty -name databaseName -value $sql.name
                        $AzurePostgreSQLDatabase | Add-Member -type NoteProperty -name databaseCollation -value $sql.properties.collation
                        $AzurePostgreSQLDatabase | Add-Member -type NoteProperty -name properties -value $sql.properties
                        $AzurePostgreSQLDatabase | Add-Member -type NoteProperty -name rawObject -value $sql
                        #Add to list
                        $AllPostgreSQLDatabases+=$AzurePostgreSQLDatabase
                    }
                    #Create object for each server configuration found
                    foreach ($SingleConfiguration in $PostgreSQLServerConfiguration){
                        $AzurePostgreSQLServerConfiguration = New-Object -TypeName PSCustomObject
                        $AzurePostgreSQLServerConfiguration | Add-Member -type NoteProperty -name serverName -value $server.name
                        $AzurePostgreSQLServerConfiguration | Add-Member -type NoteProperty -name parameterName -value $SingleConfiguration.name
                        $AzurePostgreSQLServerConfiguration | Add-Member -type NoteProperty -name parameterDescription -value $SingleConfiguration.properties.description
                        $AzurePostgreSQLServerConfiguration | Add-Member -type NoteProperty -name parameterValue -value $SingleConfiguration.properties.value
                        $AzurePostgreSQLServerConfiguration | Add-Member -type NoteProperty -name parameterDefaultValue -value $SingleConfiguration.properties.defaultValue
                        $AzurePostgreSQLServerConfiguration | Add-Member -type NoteProperty -name properties -value $SingleConfiguration.properties
                        $AzurePostgreSQLServerConfiguration | Add-Member -type NoteProperty -name rawObject -value $SingleConfiguration
                        #Add to list
                        $AllPostgreSQLServerConfigurations+=$AzurePostgreSQLServerConfiguration
                    }
                }
            }
        }
    }
    End{
        if($AllPostgreSQLServers){
            $AllPostgreSQLServers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzurePostgreSQLServer')
            [pscustomobject]$obj = @{
                Data = $AllPostgreSQLServers
            }
            $returnData.az_postgresql_servers = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PostgreSQL Server", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePostgreSQLEmptyResponse');
            }
            Write-Warning @msg
        }
        if($AllPostgreSQLDatabases){
            #Add Databases to list
            $AllPostgreSQLDatabases.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzurePostgreSQLDatabases')
            [pscustomobject]$obj = @{
                Data = $AllPostgreSQLDatabases
            }
            $returnData.az_postgresql_databases = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PostgreSQL Databases", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePostgreSQLEmptyResponse');
            }
            Write-Warning @msg
        }
        if($AllPostgreSQLServerConfigurations){
            #Add Server configuration to list
            $AllPostgreSQLServerConfigurations.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzurePostgreSQLSingleConfiguration')
            [pscustomobject]$obj = @{
                Data = $AllPostgreSQLServerConfigurations
            }
            $returnData.az_postgresql_configuration = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PostgreSQL Configurations", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePostgreSQLEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
