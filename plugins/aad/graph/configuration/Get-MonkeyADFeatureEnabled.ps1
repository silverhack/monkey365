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


Function Get-MonkeyADFeatureEnabled{
    <#
        .SYNOPSIS
		Plugin to extract information about existing features enabled in Azure AAD

        .DESCRIPTION
		Plugin to extract information about existing features enabled in Azure AAD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADFeatureEnabled
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
        $features = $null
        #Excluded auth
        $ExcludedAuths = @("certificate_credentials","client_credentials")
        #Getting Environment
        $Environment = $O365Object.Environment
        #Get Graph Authentication
        $AADAuth = $O365Object.auth_tokens.Graph
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure AD Features", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphADFeatures');
        }
        Write-Information @msg
        $allowed_features = @(
            'AllowEmailVerifiedUsers',
            'AllowInvitations',
            'AllowMemberUsersToInviteOthersAsMembers',
            'AllowUsersToChangeTheirDisplayName',
            'B2CFeature',
            'BlockAllTenantAuth',
            'ConsentedForMigrationToPublicCloud',
            'EnableExchangeDualWrite',
            'EnableHiddenMembership',
            'EnableSharedEmailDomainApis',
            'EnableWindowsLegacyCredentials',
            'EnableWindowsSupplementalCredentials',
            'ElevatedGuestsAccessEnabled',
            'ExchangeDualWriteUsersV1',
            'GuestsCanInviteOthersEnabled',
            'InvitationsEnabled',
            'LargeScaleTenant',
            'TestTenant',
            'USGovTenant',
            'DisableOnPremisesWindowsLegacyCredentialsSync',
            'DisableOnPremisesWindowsSupplementalCredentialsSync',
            'RestrictPublicNetworkAccess',
            'AutoApproveSameTenantRequests',
            'RedirectPpeUsersToMsaInt'
        )
        if($ExcludedAuths -contains $O365Object.AuthType){
            Write-Warning ("This request is not allowed with {0} authentication flow" -f $O365Object.AuthType)
        }
    }
    Process{
        $features = @{}
        $OwnQuery = ("{0}/myorganization/isDirectoryFeatureEnabled?api-version=1.61-internal" -f $Environment.Graph)
        if($null -ne $Environment -and $null -ne $AADAuth){
            foreach($feature in $allowed_features){
                $postData = @{
                    directoryFeature = $feature
                } | ConvertTo-Json
                $params = @{
                    Authentication = $AADAuth;
                    OwnQuery = $OwnQuery;
                    Data = $postData;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "POST";
                    returnRawResponse = $true;
                }
                $returned_feature = Get-MonkeyGraphObject @params
                if($null -ne $returned_feature -and $returned_feature.psobject.Properties.name.Contains('value')){
                    $features.Add($feature,$returned_feature.Value)
                }
                #Close response
                $returned_feature.Close()
                $returned_feature.Dispose()
            }
        }
    }
    End{
        if($null -ne $features){
            $features.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.FeatureInfo')
            [pscustomobject]$obj = @{
                Data = $features
            }
            $returnData.aad_enabled_features = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD Features", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureADFeaturesEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
