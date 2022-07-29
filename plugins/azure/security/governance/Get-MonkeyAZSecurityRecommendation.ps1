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


Function Get-MonkeyAZSecurityRecommendation{
    <#
        .SYNOPSIS
		Plugin to get security recommendations from Azure

        .DESCRIPTION
		Plugin to get security recommendations from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZSecurityRecommendation
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
        $AzureAdvisorConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureRecommendations"} | Select-Object -ExpandProperty resource
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Security recommendations", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureSecRecommendationInfo');
        }
        Write-Information @msg
        #Get security recommendations
        $URI = ("{0}{1}/providers/Microsoft.Advisor/recommendations?api-Version={2}" `
                -f $O365Object.Environment.ResourceManager,$O365Object.current_subscription.id,$AzureAdvisorConfig.api_version)
        $params = @{
            Authentication = $rm_auth;
            OwnQuery = $URI;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
        }
        $azure_recommendations = Get-MonkeyRMObject @params
    }
    End{
        if($azure_recommendations){
            $azure_recommendations.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Recommendations')
            [pscustomobject]$obj = @{
                Data = $azure_recommendations
            }
            $returnData.az_security_tips = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Security Recommendations", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureSecRecommendationsEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
