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

Function Get-MonkeyRBACMember{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyRBACMember
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$RoleObjectId, #= "acdd72a7-3385-48ef-bd42-f606fba81ae7",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Switch]$CurrentUser

        )
    Begin{
        $az_role_assignments = $null
        $Script:all_aad_groups = @()
        if($CurrentUser -AND $O365Object.userPrincipalName){
            $msg = @{
                MessageData = ($message.UserPermissionsMessage -f $O365Object.userPrincipalName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRbacInfo');
            }
            Write-Information @msg
        }
        #Get Classic administrators
        $classic_administrators = Get-MonkeyAzClassicAdministrator
        #Get Role assignments
        if($PSBoundParameters.ContainsKey('RoleObjectId') -and $PSBoundParameters.RoleObjectId){
            $az_role_assignments = Get-MonkeyAzRoleAssignment -RoleObjectId $PSBoundParameters.RoleObjectId
        }
        else{
            $az_role_assignments = Get-MonkeyAzRoleAssignment
        }
    }
    Process{
        if($CurrentUser -and $null -ne $az_role_assignments){
            #Check if user or application
            if($O365Object.isConfidentialApp){
                $my_permissions = $az_role_assignments | Where-Object {$_.applications.principalId -eq $O365Object.clientApplicationId} -ErrorAction Ignore | Select-Object RoleName, RoleDescription, RoleType, CreatedOn, updatedOn, RoleId -ErrorAction Ignore
                $app = $az_role_assignments.applications | Where-Object {$_.principalId -eq $O365Object.clientApplicationId} | Select-Object -Unique
                $my_permissions = New-Object PSObject -property $([ordered]@{
                    user = $app;
                    userPrincipalName = $user.appId;
                    displayName = $app.displayName;
                    permissions = $my_permissions;
                })
            }
            else{
                #Get Permissions
                $my_permissions = @()
                foreach($role_assignment in $az_role_assignments){
                    if($role_assignment.users.Count -gt 0){
                        $matched = $role_assignment.users | Where-Object {if($_.psobject.properties.item('objectId')){$_.objectId -eq $O365Object.userId}} -ErrorAction Ignore
                        if($null -ne $matched){
                            $my_permissions += $role_assignment | Select-Object RoleName, RoleDescription, RoleType, CreatedOn, updatedOn, RoleId -ErrorAction Ignore
                        }
                    }
                }
                #$my_permissions = $az_role_assignments | Where-Object {if($_.users.psobject.properties.item('objectId')){$_.users.objectId -eq $O365Object.userId}} -ErrorAction Ignore | Select-Object RoleName, RoleDescription, RoleType, CreatedOn, updatedOn, RoleId -ErrorAction Ignore
                $user = $az_role_assignments.users | Where-Object {$_.objectId -eq $O365Object.userId} | Select-Object -Unique
                if($user){
                    $my_permissions = New-Object PSObject -property $([ordered]@{
                        user = $user;
                        userPrincipalName = $user.userPrincipalName;
                        displayName = $user.displayName;
                        permissions = $my_permissions;
                        all_perms = $az_role_assignments;
                    })
                }
                else{
                    $msg = @{
                        MessageData = ($message.RBACUserInfoError -f $O365Object.userPrincipalName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureRBACUsers');
                    }
                    Write-Warning @msg
                    #Probably a classic admin
                    $roles = $classic_administrators.properties | Where-Object {$_.emailAddress -eq $O365Object.userPrincipalName} | Select-Object -ExpandProperty role
                    if($null -ne $roles){
                        $classicRoles = @()
                        foreach($role in $roles.Split(';')){
                            $classicRoles+=[pscustomobject]@{
                                RoleName = $role
                            }
                        }
                        #Get user
                        $user = Get-MonkeyADObjectByObjectId -ObjectId $O365Object.userId
                        $my_permissions = New-Object PSObject -property $([ordered]@{
                            user = $user;
                            userPrincipalName = $user.userPrincipalName;
                            displayName = $user.displayName;
                            permissions = $classicRoles;
                        })
                    }
                }
            }
        }
        else{
            $my_permissions = $az_role_assignments
        }
    }
    End{
        $my_permissions
    }
}
