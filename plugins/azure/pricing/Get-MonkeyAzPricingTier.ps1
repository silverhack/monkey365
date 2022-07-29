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


Function Get-MonkeyAzPricingTier{
    <#
        .SYNOPSIS
		Plugin to get pricing tier from Azure

        .DESCRIPTION
		Plugin to get pricing tier from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzPricingTier
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
        $pricing_config = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azurePricings"} | Select-Object -ExpandProperty resource
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Pricing", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzurePricingInfo');
        }
        Write-Information @msg
        #Get legacy pricing tier
        $params = @{
            Authentication = $rm_auth;
            Provider = $pricing_config.provider;
            ObjectType= 'pricings';
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $pricing_config.api_version;
        }
        $legacy_pricing_tier = Get-MonkeyRMObject @params
        #Get new pricing tier
        $params = @{
            Authentication = $rm_auth;
            Provider = $pricing_config.provider;
            ObjectType= 'pricings';
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = "2018-06-01";
        }
        $new_pricing_tier = Get-MonkeyRMObject @params
    }
    End{
        if($new_pricing_tier){
            $new_pricing_tier.PSObject.TypeNames.Insert(0,'Monkey365.Azure.PricingTier')
            [pscustomobject]$obj = @{
                Data = $new_pricing_tier
            }
            $returnData.az_pricing_tier = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Pricing tier", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePricingEmptyResponse');
            }
            Write-Warning @msg
        }
        #Set Legacy
        if($legacy_pricing_tier){
            $legacy_pricing_tier.PSObject.TypeNames.Insert(0,'Monkey365.Azure.LegacyPricingTier')
            [pscustomobject]$obj = @{
                Data = $legacy_pricing_tier
            }
            $returnData.az_legacy_pricing_tier = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Pricing tier", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureLegacyPricingEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
