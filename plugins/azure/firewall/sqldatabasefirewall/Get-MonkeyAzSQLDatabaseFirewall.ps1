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


Function Get-MonkeyAZSQLDatabaseFirewall{
    <#
        .SYNOPSIS
		Plugin to get Firewall Rules from each SQL Server from Azure

        .DESCRIPTION
		Plugin to get Firewall Rules from each SQL Server from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZSQLDatabaseFirewall
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
        $AzureSQLConfigFW = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureForSQLFW"} | Select-Object -ExpandProperty resource
        #Get Mysql Servers
        $DatabaseServers = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Sql/servers'}
        if(-NOT $DatabaseServers){continue}
        #Set array
        $AllFWRules = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure SQL Database firewall", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureSQLFWInfo');
        }
        Write-Information @msg
        if($DatabaseServers){
            foreach($Server in $DatabaseServers){
                if($Server.name -AND $Server.id){
                    $msg = @{
                        MessageData = ($message.AzureUnitResourceMessage -f $Server.name, "SQL Firewall rules");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $InformationAction;
                        Tags = @('AzureSQLFWInfo');
                    }
                    Write-Information @msg
                    $uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, `
                                                            $server.id, `
                                                            "firewallrules", `
                                                            $AzureSQLConfigFW.api_version)
                    #Get database info
                    $params = @{
                        Authentication = $rm_auth;
                        OwnQuery = $uri;
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                    }
                    $FWRules = Get-MonkeyRMObject @params
                    if($FWRules.properties){
                        foreach ($rule in $FWRules){
                            $AzureDBFWRule = New-Object -TypeName PSCustomObject
                            $AzureDBFWRule | Add-Member -type NoteProperty -name ServerName -value $server.name
                            $AzureDBFWRule | Add-Member -type NoteProperty -name Location -value $server.location
                            $AzureDBFWRule | Add-Member -type NoteProperty -name ResourceGroupName -value $server.id.Split("/")[4]
                            $AzureDBFWRule | Add-Member -type NoteProperty -name RuleLocation -value $rule.location
                            $AzureDBFWRule | Add-Member -type NoteProperty -name Kind -value $rule.kind
                            $AzureDBFWRule | Add-Member -type NoteProperty -name RuleName -value $rule.name
                            $AzureDBFWRule | Add-Member -type NoteProperty -name StartIpAddress -value $rule.properties.startIpAddress
                            $AzureDBFWRule | Add-Member -type NoteProperty -name EndIpAddress -value $rule.properties.endIpAddress
                            $AzureDBFWRule | Add-Member -type NoteProperty -name rawObject -value $rule
                            #Decorate object and add to list
                            $AzureDBFWRule.PSObject.TypeNames.Insert(0,'Monkey365.Azure.DatabaseFirewall')
                            $AllFWRules+= $AzureDBFWRule
                        }
                    }
                }
            }
        }
    }
    End{
        if($AllFWRules){
            $AllFWRules.PSObject.TypeNames.Insert(0,'Monkey365.Azure.DatabaseFirewall')
            [pscustomobject]$obj = @{
                Data = $AllFWRules
            }
            $returnData.az_sql_database_fw = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure SQL firewall rules", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureSQLFWEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
