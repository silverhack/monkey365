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

function Get-MonkeyAADPortalManagedAppByPrincipalID {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADPortalManagedAppByPrincipalID
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
            [Parameter(HelpMessage="user managed app")]
            [object]
            $user_managed_app
    )
    Begin{
        $principalId = $null
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.AzurePortal
    }
    Process{
        try{
            if($null -ne ($user_managed_app.Psobject.Properties.Item('principalIds'))){
                foreach($principalId in $user_managed_app.principalIds){
                    #Get user's info
                    $params = @{
                        Authentication = $AADAuth;
                        Query = ("UserDetails/{0}" -f $principalId);
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                        InformationAction = $O365Object.InformationAction;
			            Verbose = $O365Object.Verbose;
			            Debug = $O365Object.Debug;
                    }
                    $user_details = Get-MonkeyAzurePortalObject @params
                    if($user_details){
                        $principalId = [PSCustomObject]@{
                            "UserDisplayName"=$user_details.displayName
                            "UserPrincipalName"=$user_details.userPrincipalName
                            "accountEnabled"=$user_details.accountEnabled
                            "userPrincipalId" = $principalId
                            "appId"=$user_managed_app.appId
                            "appDisplayName"=$user_managed_app.displayName
                            "Resource"=$user_managed_app.resourceName
                            "Permission"=$user_managed_app.permissionId
                            "RoleOrScopeClaim"=$user_managed_app.roleOrScopeClaim
                            "Description"=$user_managed_app.permissionDescription
                        }
                    }
                    else{
                        $principalId = [PSCustomObject]@{
                            "UserDisplayName"=$null
                            "UserPrincipalName"=$null
                            "accountEnabled"=$null
                            "userPrincipalId" = $principalId
                            "appId"=$user_managed_app.appId
                            "appDisplayName"=$user_managed_app.displayName
                            "Resource"=$user_managed_app.resourceName
                            "Permission"=$user_managed_app.permissionId
                            "RoleOrScopeClaim"=$user_managed_app.roleOrScopeClaim
                            "Description"=$user_managed_app.permissionDescription
                        }
                    }
                }
            }
        }
        catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $InformationAction;
                Tags = @('AzurePortalManagedAppIdEmptyResponse');
            }
            Write-Warning @msg
        }
    }
    End{
        if($null -ne $principalId){
            $principalId
        }
    }
}
