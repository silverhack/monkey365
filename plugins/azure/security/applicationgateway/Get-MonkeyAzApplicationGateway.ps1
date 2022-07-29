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


Function Get-MonkeyAZApplicationGateway{
    <#
        .SYNOPSIS
		Plugin to get info regarding application gateway from Azure

        .DESCRIPTION
		Plugin to get info regarding application gateway from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZApplicationGateway
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
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Config
        $AzureAPPGTWConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureAppGateway"} | Select-Object -ExpandProperty resource
        #Get application gateways
        $app_gateways = $O365Object.all_resources | Where-Object {$_.type -eq 'Microsoft.Network/applicationGateways'}
        if(-NOT $app_gateways){continue}
        #set array
        $all_app_gtws = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure application gateway", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureAppGatewayInfo');
        }
        Write-Information @msg
        if($app_gateways){
            foreach($app_gtw in $app_gateways){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $app_gtw.id, "application gateway");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureAppGatewayInfo');
                }
                Write-Information @msg
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$app_gtw.id, `
                            $AzureAPPGTWConfig.api_version)

                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $my_app_gtw = Get-MonkeyRMObject @params
                if($my_app_gtw){
                    $all_app_gtws+=$my_app_gtw
                }
            }
        }
    }
    End{
        if($all_app_gtws){
            $all_app_gtws.PSObject.TypeNames.Insert(0,'Monkey365.Azure.application_gateways')
            [pscustomobject]$obj = @{
                Data = $all_app_gtws
            }
            $returnData.az_app_gateway_properties = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure application gateway", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureAppGatewayEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
