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

Function Get-MonkeyAzIAMPermission{
    <#
        .SYNOPSIS

        Get Azure IAM permission

        .DESCRIPTION

        Get Azure IAM permission

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzIAMPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(DefaultParameterSetName='All')]
    Param (
        [parameter(Mandatory=$true, ParameterSetName = 'PrincipalId', HelpMessage="Principal Id")]
        [String]$PrincipalId,

        [parameter(Mandatory=$true, ParameterSetName = 'Group', HelpMessage="Group Id")]
        [String]$GroupId,

        [parameter(Mandatory=$true, ParameterSetName = 'User', HelpMessage="User Id")]
        [String]$UserId,

        [parameter(Mandatory=$true, ParameterSetName = 'CurrentUser', HelpMessage="CurrentUser")]
        [Switch]$CurrentUser,

        [parameter(Mandatory=$true, ParameterSetName = 'ResourceGroup', HelpMessage="Resource group")]
        [String]$ResourceGroup,

        [parameter(Mandatory=$true, ParameterSetName = 'Subscription', HelpMessage="Subscription")]
        [String]$Subscription,

        [parameter(Mandatory=$false, HelpMessage="At scope query")]
        [Switch]$AtScope
    )
    Begin{
        #Get Classic administrators
        $classic_administrators = Get-MonkeyAzClassicAdministrator
        #Get Role definitions
        $roleDefinitionObjects = Get-MonkeyAzRoleDefinitionObject
        #Get Metadata
        $RACommandMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-MonkeyAzRoleAssignmentForObject")
        $newPsboundParams = @{}
        if($null -ne $RACommandMetadata){
            $param = $RACommandMetadata.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
        }
        #Add verbose, debug, etc..
        [void]$newPsboundParams.Add('InformationAction',$O365Object.InformationAction)
        [void]$newPsboundParams.Add('Verbose',$O365Object.verbose)
        [void]$newPsboundParams.Add('Debug',$O365Object.debug)
        #Role assignment
        $az_role_assignments = Get-MonkeyAzRoleAssignmentForObject @newPsboundParams
    }
    Process{
        switch ($PSCmdlet.ParameterSetName){
            { @("PrincipalId", "Group", "User", "CurrentUser") -contains $_ }{
                $rbacArray = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                if($null -ne $az_role_assignments -and $null -ne $roleDefinitionObjects){
                    foreach($ra in @($az_role_assignments)){
                        $rd = $roleDefinitionObjects.Where({$_.id -eq $ra.properties.roleDefinitionId})
                        $roleObject = [PsCustomObject]@{
                            RoleTemplateId = $rd.name;
                            RoleId = $rd.id;
                            RoleName = $rd.properties.roleName;
                            RoleType = $rd.properties.type;
                            RoleDescription = $rd.properties.description;
                            RolePermissions = $rd.properties.permissions;
                            PrincipalId = $ra.properties.principalId;
                            PrincipalType = $ra.properties.principalType;
                            Scope = $ra.properties.scope;
                            Condition = $ra.properties.condition;
                            ConditionVersion = $ra.properties.conditionVersion;
                            delegatedManagedIdentityResourceId = $ra.properties.delegatedManagedIdentityResourceId;
                            AssignedTo = $ra.properties.principalType;
                            AssignedRoleScope = $rd.properties.assignableScopes;
                            createdOn = $ra.properties.createdOn;
                            updatedOn = $ra.properties.updatedOn;
                            createdBy = $ra.properties.createdBy;
                            updatedBy = $ra.properties.updatedBy;
                        }
                        [void]$rbacArray.Add($roleObject);
                    }
                }
                Write-Output $rbacArray -NoEnumerate
                break
            }
            { @("ResourceGroup", "Subscription","All") -contains $_ }{
                $all_identities = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                if($null -ne $az_role_assignments -and $null -ne $roleDefinitionObjects){
                    #Get unique Id
                    $uniqueId = $az_role_assignments.properties.principalId | Select-Object -Unique
                    #Get identities
                    $identities = Get-MonkeyMSGraphDirectoryObjectById -Ids $uniqueId
                    foreach($Id in $uniqueId){
                        $identity = @($identities).Where({$_.id -eq $Id})
                        #Set new array
                        $rbacArray = New-Object System.Collections.Generic.List[System.Object]
                        #Get role assignments for id
                        $unitRBAC = @($az_role_assignments).Where({$_.properties.principalId -eq $Id})
                        foreach($ra in $unitRBAC){
                            $rd = @($roleDefinitionObjects).Where({$_.id -eq $ra.properties.roleDefinitionId})
                            #Create PsObject
                            $roleObject = [PsCustomObject]@{
                                RoleTemplateId = $rd.name;
                                RoleId = $rd.id;
                                RoleName = $rd.properties.roleName;
                                RoleType = $rd.properties.type;
                                RoleDescription = $rd.properties.description;
                                RolePermissions = $rd.properties.permissions;
                                PrincipalId = $ra.properties.principalId;
                                PrincipalType = $ra.properties.principalType;
                                Scope = $ra.properties.scope;
                                Condition = $ra.properties.condition;
                                ConditionVersion = $ra.properties.conditionVersion;
                                delegatedManagedIdentityResourceId = $ra.properties.delegatedManagedIdentityResourceId;
                                AssignedTo = $ra.properties.principalType;
                                AssignedRoleScope = $rd.properties.assignableScopes;
                                createdOn = $ra.properties.createdOn;
                                updatedOn = $ra.properties.updatedOn;
                                createdBy = $ra.properties.createdBy;
                                updatedBy = $ra.properties.updatedBy;
                            }
                            [void]$rbacArray.Add($roleObject);
                        }
                        #Add role object to identity
                        $identity | Add-Member -type NoteProperty -name roleAssignmentInfo -value $rbacArray -Force
                    }
                    foreach($identity in @($identities).Where({$_.'@odata.type' -ne '#microsoft.graph.group'})){
                        [void]$all_identities.Add($identity);
                    }
                    #Get only groups
                    $groups = @($identities).Where({$_.'@odata.type' -eq '#microsoft.graph.group'})
                    if($groups.Count -gt 0){
                        foreach($grp in $groups){
                            $p = @{
                                GroupId = $grp.id;
                                Parents = @(('{0}' -f $grp.id));
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $members = Get-MonkeyMSGraphGroupTransitiveMember @p
                            if($members){
                                foreach($member in $members){
                                    $member | Add-Member -type NoteProperty -name roleAssignmentInfo -value $grp.roleAssignmentInfo -Force
                                    [void]$all_identities.Add($member)
                                }
                            }
                        }
                    }
                    #Check for classic administrators
                    if($null -ne $classic_administrators){
                        #Get unique emailAddress
                        $all_emails = $classic_administrators.emailAddress | Select-Object -Unique
                        foreach($email in @($all_emails)){
                            $identity = $all_identities.Where({$_.'@odata.type' -eq '#microsoft.graph.user' -and $_.userPrincipalName -eq $email})
                            if($identity.Count -gt 0){
                                #get All roles
                                $all_classic = @($classic_administrators).Where({$_.emailAddress -eq $email})
                                foreach($classic in $all_classic){
                                    $roleObject = [PsObject]@{
                                        RoleTemplateId = $null;
                                        RoleId = $classic.rawObject.id;
                                        RoleName = $classic.Role;
                                        RoleType = 'classicRole';
                                        RoleDescription = $null;
                                        RolePermissions = $null;
                                        AssignedRoleScope = $null;
                                        createdOn = $null;
                                        updatedOn = $null;
                                        createdBy = $null;
                                        updatedBy = $null;
                                    }
                                    #Add to object
                                    [void]$identity[0].roleAssignmentInfo.Add($roleObject)
                                }
                            }
                        }
                    }
                }
                Write-Output $all_identities -NoEnumerate
                break
            }
        }
    }
    End{
        #Nothing to do here
    }
}
