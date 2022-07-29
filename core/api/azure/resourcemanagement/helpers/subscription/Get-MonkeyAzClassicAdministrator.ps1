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

Function Get-MonkeyAzClassicAdministrator{
    <#
        .SYNOPSIS
        Get classic administrators from Azure subscription

        .DESCRIPTION
        Get classic administrators from Azure subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzClassicAdministrator
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param ()
    Begin{
        $AzureAuthConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureAuthorization"} | Select-Object -ExpandProperty resource
        #Get auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Set null
        $classic_administrators = $null
    }
    Process{
        try{
            if($null -ne $rm_auth -and $null -ne $O365Object.current_subscription){
                $msg = @{
                    MessageData = ($message.ClassicAdminsInfoMessage -f $O365Object.current_subscription.subscriptionId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureRbacInfo');
                }
                Write-Information @msg
                #Get Classic Administrators
                $params = @{
                    Authentication = $rm_auth;
                    Provider = $AzureAuthConfig.provider;
                    ObjectType = "classicAdministrators";
                    Environment = $O365Object.Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $AzureAuthConfig.api_version;
                }
                $classic_administrators = Get-MonkeyRMObject @params
            }
            else{
                $msg = @{
                    MessageData = ($message.ClassicAdminsWarningMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureClassicAdminWarning');
                }
                Write-Warning @msg
            }
        }
        catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureClassicAdminError');
            }
            Write-Error @msg
            $msg = @{
                MessageData = ($_.Exception.StackTrace);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureClassicAdminDebugError');
            }
            Write-Debug @msg
        }
    }
    End{
        if($null -ne $classic_administrators){
            return $classic_administrators
        }
    }
}