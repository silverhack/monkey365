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


Function Get-MonkeyADUserFeaturePreview{
    <#
        .SYNOPSIS
		Plugin to get user feature preview info from Azure AD

        .DESCRIPTION
		Plugin to get user feature preview info from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADUserFeaturePreview
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
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.AzurePortal
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure AD user feature preview", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzurePortalUserFeatPreview');
        }
        Write-Information @msg
        #Get Device Settings
        $params = @{
            Authentication = $AADAuth;
            Query = 'Directories/FeatureSettingsProperties';
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
        }
        $ad_user_feature_preview = Get-MonkeyAzurePortalObject @params
    }
    End{
        if ($ad_user_feature_preview){
            $ad_user_feature_preview.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.UserFeaturePreview')
            [pscustomobject]$obj = @{
                Data = $ad_user_feature_preview
            }
            $returnData.aad_user_feature_preview = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD user feature preview", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePortalUserFeatEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
