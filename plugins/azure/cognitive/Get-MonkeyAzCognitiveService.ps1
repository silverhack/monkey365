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



Function Get-MonkeyAzCognitiveService{
    <#
        .SYNOPSIS
		Azure Cognitive Service
        https://docs.microsoft.com/en-us/rest/api/cognitiveservices/

        .DESCRIPTION
		Azure Cognitive Service
        https://docs.microsoft.com/en-us/rest/api/cognitiveservices/

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzCognitiveService
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
        $CognitiveAPI = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureCognitive"} | Select-Object -ExpandProperty resource
        #Get Cognitive Services accounts
        $cognitive_services = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.CognitiveServices/accounts'}
        if(-NOT $cognitive_services){continue}
        $all_cognitive_services = @();
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Cognitive Services", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureCognitiveInfo');
        }
        Write-Information @msg
        #Get All Cognitive accounts
        if($cognitive_services){
            foreach($cognitive_service in $cognitive_services){
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$cognitive_service.id,`
                            $CognitiveAPI.api_version)
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $my_cognitive_account = Get-MonkeyRMObject @params
                if($my_cognitive_account){
                    #Get Network properties
                    if(-NOT $my_cognitive_account.properties.NetworkRuleSet){
                        $my_cognitive_account | Add-Member -type NoteProperty -name allowAccessFromAllNetworks -value $true
                    }
                    else{
                        $my_cognitive_account | Add-Member -type NoteProperty -name allowAccessFromAllNetworks -value $false
                    }
                    #Add cognitive account to array
                    $all_cognitive_services += $my_cognitive_account
                }
            }
        }
    }
    End{
        if($all_cognitive_services){
            $all_cognitive_services.PSObject.TypeNames.Insert(0,'Monkey365.Azure.CognitiveAccounts')
            [pscustomobject]$obj = @{
                Data = $all_cognitive_services
            }
            $returnData.az_cognitive_accounts = $obj
        }
        else{
           $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Cognitive Services", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureCognitiveEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
