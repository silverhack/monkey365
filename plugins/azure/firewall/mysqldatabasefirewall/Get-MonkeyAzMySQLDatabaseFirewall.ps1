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



Function Get-MonkeyAZMysqlDatabaseFirewall{
    <#
        .SYNOPSIS
		Plugin to get Firewall Rules from each MySQL Server from Azure
        https://docs.microsoft.com/en-us/rest/api/mysql/firewallrules/listbyserver

        .DESCRIPTION
		Plugin to get Firewall Rules from each MySQL Server from Azure
        https://docs.microsoft.com/en-us/rest/api/mysql/firewallrules/listbyserver

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZMysqlDatabaseFirewall
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
        #set array
        $AllMySQLFWRules = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Mysql database firewall", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureMysqlFWsInfo');
        }
        Write-Information @msg
        if($DatabaseServers){
            foreach($Server in $DatabaseServers){
                if($Server.name -AND $Server.id){
                    $msg = @{
                        MessageData = ($message.AzureUnitResourceMessage -f $Server.name, "MySQL firewall rules");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $InformationAction;
                        Tags = @('AzureMySQLServerInfo');
                    }
                    Write-Information @msg

                    $uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, `
                                                            $server.id, "firewallrules", `
                                                            $AzureMySQLConfig.api_version)
                    #Get database info
                    $params = @{
                        Authentication = $rm_auth;
                        OwnQuery = $uri;
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                    }
                    $MySQLFWRules = Get-MonkeyRMObject @params
                    if($MySQLFWRules.properties){
                        foreach ($rule in $MySQLFWRules){
                            $AzureMySQLDBFWRule = New-Object -TypeName PSCustomObject
                            $AzureMySQLDBFWRule | Add-Member -type NoteProperty -name ServerName -value $server.name
                            $AzureMySQLDBFWRule | Add-Member -type NoteProperty -name Location -value $server.location
                            $AzureMySQLDBFWRule | Add-Member -type NoteProperty -name ResourceGroupName -value $server.id.Split("/")[4]
                            $AzureMySQLDBFWRule | Add-Member -type NoteProperty -name RuleName -value $rule.name
                            $AzureMySQLDBFWRule | Add-Member -type NoteProperty -name StartIpAddress -value $rule.properties.startIpAddress
                            $AzureMySQLDBFWRule | Add-Member -type NoteProperty -name EndIpAddress -value $rule.properties.endIpAddress
                            #Decorate object and add to list
                            $AzureMySQLDBFWRule.PSObject.TypeNames.Insert(0,'Monkey365.Azure.MySQLDatabaseFirewall')
                            $AllMySQLFWRules+= $AzureMySQLDBFWRule
                        }
                    }
                }
            }
        }
    }
    End{
        if($AllMySQLFWRules){
            $AllMySQLFWRules.PSObject.TypeNames.Insert(0,'Monkey365.Azure.MySQLDatabaseFirewall')
            [pscustomobject]$obj = @{
                Data = $AllMySQLFWRules
            }
            $returnData.az_mysql_database_fw = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure MySQL Firewall rules", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureMysqlFWEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
