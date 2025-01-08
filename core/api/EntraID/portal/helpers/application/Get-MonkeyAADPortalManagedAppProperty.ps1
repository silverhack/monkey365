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

Function Get-MonkeyAADPortalManagedAppProperty {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADPortalManagedAppProperty
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(HelpMessage="managed app")]
            [object]
            $managed_app
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.AzurePortal
    }
    Process{
        if($null -ne ($managed_app.Psobject.Properties.Item('objectId'))){
            try{
                #Get managed app info
                $params = @{
                    Authentication = $AADAuth;
                    Query = ("EnterpriseApplications/{0}/Properties?appId={1}&loadLogo=false" -f $managed_app.objectId, $managed_app.appId);
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    InformationAction = $O365Object.InformationAction;
			        Verbose = $O365Object.Verbose;
			        Debug = $O365Object.Debug;
                }
                $managed_app_extra_properties = Get-MonkeyAzurePortalObject @params
                if($null -ne $managed_app_extra_properties -and $null -ne $managed_app_extra_properties.Psobject.Properties.Item('userAccessUrl')){
                    #Add to existing object
                    $managed_app | add-member NoteProperty -name userAccessUrl -Value $managed_app_extra_properties.userAccessUrl
                    $managed_app | add-member NoteProperty -name appRoleAssignmentRequired -Value $managed_app_extra_properties.appRoleAssignmentRequired
                    $managed_app | add-member NoteProperty -name isApplicationVisible -Value $managed_app_extra_properties.isApplicationVisible
                    $managed_app | add-member NoteProperty -name isMicrosoftFirstParty -Value $managed_app_extra_properties.microsoftFirstParty
                    $managed_app | add-member NoteProperty -name termsOfServiceUrl -Value $managed_app_extra_properties.termsOfServiceUrl
                    $managed_app | add-member NoteProperty -name privacyStatementUrl -Value $managed_app_extra_properties.privacyStatementUrl
                }
                #Check for admin consent app
                $params = @{
                    Authentication = $AADAuth;
                    Query = ("EnterpriseApplications/{0}/ServicePrincipalPermissions?consentType=Admin&userObjectId=" -f $managed_app.objectId);
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    InformationAction = $O365Object.InformationAction;
			        Verbose = $O365Object.Verbose;
			        Debug = $O365Object.Debug;
                }
                $admin_consent_res_query = Get-MonkeyAzurePortalObject @params
                if($admin_consent_res_query){
                    $managed_app | add-member NoteProperty -name isAdminConsentedApp -Value $true
                    $managed_app | add-member NoteProperty -name adminConsentedPerms -Value $admin_consent_res_query
                }
                else{
                    $managed_app | add-member NoteProperty -name isAdminConsentedApp -Value $false
                    $managed_app | add-member NoteProperty -name adminConsentedPerms -Value $null
                }
                #Check for user consent app
                $params = @{
                    Authentication = $AADAuth;
                    Query = ("EnterpriseApplications/{0}/ServicePrincipalPermissions?consentType=User&userObjectId=" -f $managed_app.objectId);
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    InformationAction = $O365Object.InformationAction;
			        Verbose = $O365Object.Verbose;
			        Debug = $O365Object.Debug;
                }
                $user_consent_res_query = Get-MonkeyAzurePortalObject @params
                if($user_consent_res_query){
                    $managed_app | add-member NoteProperty -name isUserConsentedApp -Value $true
                    $managed_app | add-member NoteProperty -name userConsentedPerms -Value $user_consent_res_query
                }
                else{
                    $managed_app | add-member NoteProperty -name isUserConsentedApp -Value $false
                    $managed_app | add-member NoteProperty -name userConsentedPerms -Value $null
                }
            }
            catch{
                $msg = @{
                    MessageData = ("Unable to get application properties from {0}" -f $managed_app.objectId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Error';
                    InformationAction = $InformationAction;
                    Tags = @('AzurePortalInvalidManagedAppObject');
                }
                Write-Error @msg
            }
        }
        else{
            $msg = @{
                MessageData = ("Invalid managed application object. Object is {0}" -f $managed_app);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePortalInvalidManagedAppObject');
            }
            Write-Warning @msg
        }
    }
    End{
        #Return object
        $managed_app
    }
}

