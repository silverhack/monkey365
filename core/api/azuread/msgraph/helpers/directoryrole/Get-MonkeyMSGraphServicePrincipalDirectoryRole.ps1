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


Function Get-MonkeyMSGraphServicePrincipalDirectoryRole{
    <#
        .SYNOPSIS
		Get User directory role

        .DESCRIPTION
		Get User directory role

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphServicePrincipalDirectoryRole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="Principal Id")]
        [string]$principalId,

        [parameter(Mandatory=$false)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    try{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $msg = @{
            MessageData = ($message.ObjectIdMessageInfo -f "user's", $principalId);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphDirectoryRoleByApplicationId');
        }
        Write-Debug @msg
        #Get servicePrincipalMemberOf
        $filter = ("appId eq '{0}'" -f $principalId)
        $expand = 'MemberOf'
        $p = @{
            filter = $filter;
            Expand = $expand;
            Method = "GET";
            APIVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $service_principal = Get-MonkeyMSGraphAADServicePrincipal @p
        if($service_principal){
            $objectType = ('servicePrincipals/{0}/transitiveMemberOf' -f $service_principal.id)
            $params = @{
                Authentication = $graphAuth;
                ObjectType = $objectType;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $permissions = Get-MonkeyMSGraphObject @params | Where-Object {$_.'@odata.type' -eq '#microsoft.graph.directoryRole'}
            if(@($permissions).Count -gt 0){
                #Add to object
                $service_principal | Add-Member -type NoteProperty -name directoryRoleInfo -value $permissions -Force
            }
            else{
                $msg = @{
                    MessageData = ($message.RBACPermissionEmptyResponse -f $service_principal.appId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('RBACEmptyResponse');
                }
                Write-Warning @msg
                #Add to object
                $service_principal | Add-Member -type NoteProperty -name directoryRoleInfo -value $null -Force
            }
            #Return managed identity permissions
            if($null -ne $service_principal){
                return $service_principal
            }
        }
    }
    catch{
        $msg = @{
            MessageData = ("Unable to get servicePrincipal's directory role information from id {0}" -f $principalId);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphSPDirectoryRole');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        Write-Verbose @msg
    }
}
