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


Function Get-MonkeyAZNetworkWatcher{
    <#
        .SYNOPSIS
		Plugin to get network watcher from Azure

        .DESCRIPTION
		Plugin to get network watcher from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZNetworkWatcher
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
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Network Watcher locations
        $network_watcher_locations = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Network/networkWatchers'} | Select-Object -ExpandProperty location
        #Get Network watcher IDs
        $network_watchers = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Network/networkWatchers'} | Select-Object id, location
        #Get Network Security groups
        $network_security_groups = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Network/networkSecurityGroups' -or $_.type -like 'Microsoft.ClassicNetwork/networkSecurityGroups'} | Select-Object id, location
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Network Watcher", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureNetworkWatcherInfo');
        }
        Write-Information @msg
        #Get All locations
        $URI = ("{0}{1}/locations?api-Version={2}" `
                -f $O365Object.Environment.ResourceManager,$O365Object.current_subscription.id,'2016-06-01')
        $params = @{
            Authentication = $rm_auth;
            OwnQuery = $URI;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
        }
        $azure_locations = Get-MonkeyRMObject @params
        $locations = $azure_locations | Select-Object -ExpandProperty name
        if($network_watcher_locations -and $locations){
            #Compare objects
            $effective_nw_locations = Compare-Object -ReferenceObject $network_watcher_locations -DifferenceObject $locations -PassThru
            if($effective_nw_locations){
                $network_watcher = New-Object -TypeName PSCustomObject
                $network_watcher | Add-Member -type NoteProperty -name all_locations_enabled -value $false
                $network_watcher | Add-Member -type NoteProperty -name locations -value (@($effective_nw_locations) -join ',')
            }
            else{
                $network_watcher = New-Object -TypeName PSCustomObject
                $network_watcher | Add-Member -type NoteProperty -name all_locations_enabled -value $true
                $network_watcher | Add-Member -type NoteProperty -name locations -value (@($network_watcher_locations) -join ',')
            }
        }
        #Check if flow logs are enabled
        if($network_watchers){
            $all_nsg_flows = @()
            foreach($nw in $network_watchers){
                $region_nws = $network_security_groups | Where-Object {$_.location -eq $nw.location} | Select-Object -ExpandProperty id
                if($region_nws){
                    foreach($network in $region_nws){
                        #Get flow log
                        $POSTDATA = @{"TargetResourceId" = $network;} | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
                        $URI = ("{0}{1}/queryFlowLogStatus?api-Version={2}" `
                                -f $O365Object.Environment.ResourceManager,$nw.id,'2018-11-01')

                        $params = @{
                            Authentication = $rm_auth;
                            OwnQuery = $URI;
                            Environment = $Environment;
                            ContentType = 'application/json';
                            Method = "POST";
                            Data = $POSTDATA;
                        }
                        $flow_log_cnf = Get-MonkeyRMObject @params
                        if($flow_log_cnf){
                            $network_flow = New-Object -TypeName PSCustomObject
                            $network_flow | Add-Member -type NoteProperty -name target_resource_id -value $flow_log_cnf.targetResourceId
                            $network_flow | Add-Member -type NoteProperty -name storageId -value $flow_log_cnf.properties.storageId
                            $network_flow | Add-Member -type NoteProperty -name enabled -value $flow_log_cnf.properties.enabled
                            $network_flow | Add-Member -type NoteProperty -name retentionPolicyEnabled -value $flow_log_cnf.properties.retentionPolicy.enabled
                            $network_flow | Add-Member -type NoteProperty -name retentionPolicyDays -value $flow_log_cnf.properties.retentionPolicy.days
                            $network_flow | Add-Member -type NoteProperty -name rawObject -value $flow_log_cnf
                            #Add to array
                            $all_nsg_flows+= $network_flow;
                        }
                    }

                }

            }
        }
    }
    End{
        if($network_watcher){
            $network_watcher.PSObject.TypeNames.Insert(0,'Monkey365.Azure.NetworkWatcher')
            [pscustomobject]$obj = @{
                Data = $network_watcher
            }
            $returnData.az_network_watcher = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Network Watcher", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureKeyNetworkWatcherEmptyResponse');
            }
            Write-Warning @msg
        }
        #Add network flows
        if($all_nsg_flows){
            $all_nsg_flows.PSObject.TypeNames.Insert(0,'Monkey365.Azure.NetworkWatcher.flows_logs')
            [pscustomobject]$obj = @{
                Data = $all_nsg_flows
            }
            $returnData.az_network_watcher_flow_logs = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Network Watcher Flow Logs", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureKeyNetworkWatcherFLEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
