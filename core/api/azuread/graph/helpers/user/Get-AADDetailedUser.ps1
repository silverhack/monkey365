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

Function Get-AADDetailedUser {
    <#
        .SYNOPSIS
        Get detailed user from AzureAD

        .DESCRIPTION
        Get detailed user from AzureAD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AADDetailedUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [Object]$user
    )
    Begin{
        #Get instance
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        #Get Config
        try{
            $aadConf = $O365Object.internal_config.azuread.provider.graph
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
    }
    Process{
        if($user.objectType -eq "User"){
            $msg = @{
                MessageData = ("Getting detailed information of {0} user object" -f $user.ObjectId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphDetailedUserInfo');
            }
            Write-Debug @msg
            $uri = ("{0}/myorganization/users('{1}')?api-version={2}" `
                    -f $Environment.Graph, $user.ObjectId,$aadConf.internal_api_version)

            $params = @{
                Authentication = $AADAuth;
                OwnQuery = $uri;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
            }
            $user_details = Get-MonkeyGraphObject @params
            if($user_details){
                #extract MFA status
                $sad = $user_details.strongAuthenticationDetail.methods
                $ver_details = $user_details.strongAuthenticationDetail.verificationDetail
                $phone_app_details = $user_details.strongAuthenticationDetail.phoneAppDetails
                if($sad){
                    $default = $sad | Where-Object {$_.isDefault -eq $true}
                    $user_details | Add-Member -type NoteProperty -name preferredMfaMethod -value $default.methodType
                }
                elseif($sad.Count -eq 0 -and $ver_details){
                    if($phone_app_details.Count -gt 0 -and $ver_details.phoneNumber){
                        $user_details | Add-Member -type NoteProperty -name preferredMfaMethod -value "PhoneApp"
                    }
                    elseif($phone_app_details.Count -eq 0 -and $ver_details.email){
                        $user_details | Add-Member -type NoteProperty -name preferredMfaMethod -value "Email"
                    }
                    elseif($phone_app_details.Count -eq 0 -and $ver_details.phoneNumber){
                        $user_details | Add-Member -type NoteProperty -name preferredMfaMethod -value "PhoneNumber"
                    }
                }
                else{
                    $user_details | Add-Member -type NoteProperty -name preferredMfaMethod -value $null
                }
                if($null -eq $user_details.preferredMfaMethod){
                    $user_details | Add-Member -type NoteProperty -name mfaenabled -value $false
                }
                else{
                    $user_details | Add-Member -type NoteProperty -name mfaenabled -value $true
                }
                #[void]$all_users.Add($user_details)
                return $user_details
            }
            else{
                #No detailed user retrieved. Add old user
                #[void]$all_users.Add($user)
                $user | Add-Member -type NoteProperty -name mfaenabled -value "Unknown"
                return $user
            }
        }
        else{#Probably group, service principal, etc..
            #[void]$all_users.Add($user)
            return $user
        }
    }
    End{
        #Nothing to do here
    }
}
