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




Function Get-MonkeyAzBotChannel{
    <#
        .SYNOPSIS
		Azure Bots
        https://docs.microsoft.com/en-us/azure/bot-service/dotnet/bot-builder-dotnet-security?view=azure-bot-service-3.0
        https://github.com/Azure/azure-rest-api-specs/blob/master/specification/botservice/resource-manager/Microsoft.BotService/preview/2017-12-01/botservice.json

        .DESCRIPTION
		Azure Bots
        https://docs.microsoft.com/en-us/azure/bot-service/dotnet/bot-builder-dotnet-security?view=azure-bot-service-3.0
        https://github.com/Azure/azure-rest-api-specs/blob/master/specification/botservice/resource-manager/Microsoft.BotService/preview/2017-12-01/botservice.json

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzBotChannel
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
        $AzureBot = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureBotServices"} | Select-Object -ExpandProperty resource
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Bots", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureBotsInfo');
        }
        Write-Information @msg
        #List All Azure Bots
        $params = @{
            Authentication = $rm_auth;
            Provider = $AzureBot.provider;
            ObjectType= 'botServices';
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $AzureBot.api_version;
        }
        $azureBots = Get-MonkeyRMObject @params
    }
    End{
        if($azureBots){
            $azureBots.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Bots')
            [pscustomobject]$obj = @{
                Data = $azureBots
            }
            $returnData.az_bots = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Bots", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureBotsEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
