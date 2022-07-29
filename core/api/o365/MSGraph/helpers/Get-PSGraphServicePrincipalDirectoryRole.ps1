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


Function Get-PSGraphServicePrincipalDirectoryRole{
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
            File Name	: Get-PSGraphServicePrincipalDirectoryRole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="Principal Id")]
        [string]$principalId
    )
    try{
        $groups = $my_permissions = $null
        $ras = New-Object System.Collections.Generic.List[System.Object]
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
        $params = @{
            Authentication = $graphAuth;
            ObjectType = "servicePrincipals";
            Environment = $Environment;
            ContentType = 'application/json';
            filter = $filter;
            Expand = $expand;
            Method = "GET";
            APIVersion = 'beta';
        }
        $service_principal = Get-GraphObject @params
        if($service_principal){
            $memberOf = $service_principal.MemberOf
            if($memberOf){
                #Get roleAssignments
                $d_objects = $memberOf | Where-Object {$_.'@odata.type' -eq '#microsoft.graph.directoryRole'}
                if($d_objects){
                    [void]$ras.Add($d_objects)
                }
                $groups = $memberOf | Where-Object {$_.'@odata.type' -eq '#microsoft.graph.group'}
            }
            if($groups){
                foreach($group in $groups){
                    $memberOf = Get-PSGraphGroupDirectoryRoleMemberOf -group_id $group.Id -Parents @('')
                    if($memberOf){
                        [void]$ras.Add($memberOf)
                    }
                }
            }
            if($ras){
                $my_permissions = New-Object PSObject -property $([ordered]@{
                    user = $service_principal;
                    userPrincipalName = $service_principal.appId;
                    displayName = $service_principal.displayName;
                    permissions = ($ras | Select-Object id,displayName,Description,roleTemplateId);
                })
            }
            else{
                $msg = @{
                    MessageData = ($message.RBACPermissionErrorMessage -f $service_principal.appId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('RBACPermissionError');
                }
                Write-Warning @msg
                $my_permissions = New-Object PSObject -property $([ordered]@{
                    user = $service_principal;
                    userPrincipalName = $service_principal.appId;
                    displayName = $service_principal.displayName;
                    permissions = $ras;
                })
            }
            #Return managed identity permissions
            if($null -ne $my_permissions){
                return $my_permissions
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
