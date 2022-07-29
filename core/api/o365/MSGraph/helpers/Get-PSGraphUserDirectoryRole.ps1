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


Function Get-PSGraphUserDirectoryRole{
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
            File Name	: Get-PSGraphUserDirectoryRole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="User Id")]
        [string]$user_id
    )
    try{
        $groups = $my_permissions = $null
        $ras = New-Object System.Collections.Generic.List[System.Object]
        $msg = @{
            MessageData = ($message.ObjectIdMessageInfo -f "user's", $user_id);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphDirectoryRoleByUserId');
        }
        Write-Debug @msg
        #Get UserObject
        $userObject = Get-PSGraphUserById -user_id $user_id -expand "MemberOf"
        if($userObject){
            $memberOf = $userObject.MemberOf
            if($memberOf){
                #Get roleAssignments
                $d_objects = $memberOf | Where-Object {$_.'@odata.type' -eq '#microsoft.graph.directoryRole'}
                if($d_objects){
                    [void]$ras.Add($d_objects)
                }
                #Get groups
                $groups = $memberOf | Where-Object {$_.'@odata.type' -eq '#microsoft.graph.group'}
                if($groups){
                    foreach($group in $groups){
                        $ra_members = Get-PSGraphGroupDirectoryRoleMemberOf -group_id $group.Id -Parents @('')
                        if($ra_members){
                            foreach($ra_member in @($ra_members)){
                                [void]$ras.Add($ra_member)
                            }
                        }
                    }
                }
            }
            if($ras.Count -gt 0){
                $my_permissions = New-Object PSObject -property $([ordered]@{
                    user = $userObject;
                    userPrincipalName = $userObject.userPrincipalName;
                    displayName = $userObject.displayName;
                    permissions = $ras.ToArray(); #($ras.ToArray() | Select-Object id,displayName,Description,roleTemplateId);
                })
            }
            else{
                $msg = @{
                    MessageData = ($message.RBACPermissionErrorMessage -f $userObject.userPrincipalName);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('RBACPermissionError');
                }
                Write-Warning @msg
                $my_permissions = New-Object PSObject -property $([ordered]@{
                    user = $userObject;
                    userPrincipalName = $userObject.userPrincipalName;
                    displayName = $userObject.displayName;
                    permissions = $ras;
                })
            }
            if($null -ne $my_permissions){
                return $my_permissions
            }
        }
    }
    catch{
        $msg = @{
            MessageData = ("Unable to get user's directory role information from id {0}" -f $user_id);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphDirectoryRole');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        Write-Verbose @msg
    }
}
