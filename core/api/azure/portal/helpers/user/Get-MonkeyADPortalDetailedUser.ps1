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

function Get-MonkeyADPortalDetailedUser{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADPortalDetailedUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
            [Parameter(Mandatory=$True, HelpMessage="User")]
            [Object]$user
        )
    Begin{
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $Environment = $O365Object.Environment
        #Get Id
        if($null -ne ($user.Psobject.Properties.Item('Id'))){
            $id = $user.Id
        }
        elseif($null -ne ($user.Psobject.Properties.Item('ObjectId'))){
            $id = $user.ObjectId
        }
        else{
            $id = $null
        }
    }
    Process{
        if($null -ne $id){
            try{
                $params = @{
                    Authentication = $graphAuth;
                    ObjectType = ("users/{0}/authentication/methods" -f $id);
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = 'beta';
                }
                $auth_details = Get-GraphObject @params
                if($auth_details){
                    #Getting MFA status
                    $authenticator_enabled = $auth_details | Where-Object {$_."@odata.type" -eq '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'} -ErrorAction Ignore
                    $phone_authentication = $auth_details | Where-Object {$_."@odata.type" -eq '#microsoft.graph.phoneAuthenticationMethod'} -ErrorAction Ignore
                    if($null -ne $authenticator_enabled){
                        $user | Add-Member -type NoteProperty -name mfaenabled -value $true -Force
                    }
                    else{
                        $user | Add-Member -type NoteProperty -name mfaenabled -value $false -Force
                    }
                    if($null -ne $phone_authentication){
                        $user | Add-Member -type NoteProperty -name authenticationMethods -value $auth_details -Force
                    }
                    else{
                        $user | Add-Member -type NoteProperty -name authenticationMethods -value $false -Force
                    }
                }
                else{
                    #No detailed user retrieved. Add mfa to unknown
                    $user | Add-Member -type NoteProperty -name mfaenabled -value "Unknown" -Force
                    $user | Add-Member -type NoteProperty -name authenticationMethods -value $false -Force
                }
            }
            catch{
                $msg = @{
                    MessageData = ("Unable to get authentication properties for {0} userId" -f $id);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Error';
                    InformationAction = $InformationAction;
                    Tags = @('AzurePortalInvalidUserAuthProperty');
                }
                Write-Error @msg
                #No detailed user retrieved. Add mfa to unknown
                $user | Add-Member -type NoteProperty -name mfaenabled -value "Unknown" -Force
                $user | Add-Member -type NoteProperty -name authenticationMethods -value $false -Force
            }
        }
        else{
            Write-Warning "Unable to get Id from user object"
        }
    }
    End{
        $user
    }
}
