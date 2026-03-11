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

Function Get-MonkeyAzRoleAssignment{
    <#
        .SYNOPSIS

        Get Azure role assignment

        .DESCRIPTION

        Get Azure role assignment

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRoleAssignment
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
        [Switch]$Subscription,

        [parameter(Mandatory=$false, HelpMessage="At scope query")]
        [Switch]$AtScope
    )
    Begin{
        $allRoleDefinitions = [System.Collections.Generic.List[System.Object]]::new();
        $allRoleAssignments = [System.Collections.Generic.List[System.Object]]::new();
        Try{
            $api_Version = $O365Object.internal_config.entraId.provider.msgraph.api_version
        }
        Catch{
            $api_Version = "v1.0"
        }
        #Get Role definitions
        $roleDefinitions = Get-MonkeyAzRoleDefinitionObject
        If($null -ne $roleDefinitions){
            ForEach($roleDefinition in @($roleDefinitions)){
                $obj = [PsCustomObject]@{
                    id = $roleDefinition.id;
                    definition = $roleDefinition;
                }
                #Add to array
                [void]$allRoleDefinitions.Add($obj)
            }
        }
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
        $roleAssignments = Get-MonkeyAzRoleAssignmentForObject @newPsboundParams
    }
    Process{
        switch ($PSCmdlet.ParameterSetName){
            { @("PrincipalId", "Group", "User", "CurrentUser") -contains $_ }{
                If($null -ne $roleAssignments -and $allRoleDefinitions.Count -gt 0){
                    ForEach($assignment in @($roleAssignments).GetEnumerator()){
                        #Get Role
                        $role = $allRoleDefinitions.Where({$_.id -eq $assignment.properties.roleDefinitionId});
                        If($role.Count -eq 1){
                            #Create role object
                            $roleObject = $role[0].definition | New-MonkeyAzureRoleObject -Identity
                            $roleObject.principalId = $assignment.properties.principalId;
                            $roleObject.principalType = $assignment.properties.principalType;
                            $roleObject.scope = $assignment.properties.scope;
                            $roleObject.condition = $assignment.properties.condition;
                            $roleObject.conditionVersion = $assignment.properties.conditionVersion;
                            $roleObject.delegatedManagedIdentityResourceId = $assignment.properties.delegatedManagedIdentityResourceId;
                            $roleObject.assignmentDescription = $assignment.properties.description;
                            $roleObject.roleCreatedOn = $assignment.properties.createdOn;
                            $roleObject.roleUpdatedOn = $assignment.properties.updatedOn;
                            $roleObject.roleCreatedBy = $assignment.properties.createdBy;
                            $roleObject.roleUpdatedBy = $assignment.properties.updatedBy;
                            [void]$allRoleAssignments.Add($roleObject);
                        }
                    }
                    Write-Output $allRoleAssignments -NoEnumerate
                    break
                }
            }
            { @("ResourceGroup", "Subscription","All") -contains $_ }{
                If($null -ne $roleAssignments -and $allRoleDefinitions.Count -gt 0){
                    #Map objects
                    $mappedRoleAssignments = $roleAssignments | Group-Object -Property {$_.properties.roleDefinitionId}
                    ForEach($assignments in @($mappedRoleAssignments).GetEnumerator()){
                        #Set nested members
                        $nestedMembers = [System.Collections.Generic.List[System.Object]]::new();
                        $allnestedObjects = [System.Collections.Generic.List[System.Object]]::new();
                        #Get Role
                        $role = $allRoleDefinitions.Where({$_.id -eq $assignments.Name});
                        If($role.Count -gt 0){
                            $msg = @{
		                        MessageData = ("Getting {0} members" -f $role[0].definition.properties.roleName);
		                        callStack = (Get-PSCallStack | Select-Object -First 1);
		                        logLevel = 'info';
		                        InformationAction = $O365Object.InformationAction;
		                        Tags = @('AzureIAMInfo');
	                        }
	                        Write-Information @msg
                            #Create role object
                            $roleObject = $role[0].definition | New-MonkeyAzureRoleObject
                            #Get principals
                            $principals = $assignments.Group | Select-Object @{Label="principalId";Expression={$_.properties.principalId}}
                            $principals = $principals | Select-Object -ExpandProperty principalId -ErrorAction Ignore
                            #Get objects
                            $p = @{
                                Ids = $principals;
                                APIVersion = $api_Version;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
                            }
                            $allPrincipals = Get-MonkeyMSGraphDirectoryObjectById @p
                            #Get users
                            $roleObject.users = @($allPrincipals).Where({$_.'@odata.type' -match '#microsoft.graph.user'})
                            #Get users
                            $users = @($allPrincipals).Where({$_.'@odata.type' -match '#microsoft.graph.user'})
                            #Get groups
                            $roleObject.groups = @($allPrincipals).Where({$_.'@odata.type' -match '#microsoft.graph.group'})
                            #Get servicePrincipals
                            $servicePrincipals = @($allPrincipals).Where({$_.'@odata.type' -match '#microsoft.graph.servicePrincipal'})
                            If($roleObject.groups.Count -gt 0){
                                #get Real members
                                foreach($group in $roleObject.groups.GetEnumerator()){
                                    $p = @{
                                        GroupId = $group.id;
                                        Parents = @($group.id);
                                        APIVersion = $api_Version;
                                        Verbose = $O365Object.verbose;
                                        Debug = $O365Object.debug;
                                        InformationAction = $O365Object.InformationAction;
                                    }
                                    $groupMember = Get-MonkeyMSGraphGroupTransitiveMember @p
                                    If($groupMember){
                                        ForEach($member in $groupMember){
                                            [void]$nestedMembers.Add(
                                                [PsCustomObject]@{
                                                    id = $member.id;
                                                    objectType = If($member.'@odata.type' -match '#microsoft.graph.servicePrincipal'){'application'}Else{'user'}
                                                    member = $member;
                                                    group = $group;
                                                    groupId = $group.id;
                                                    groupName = $group.displayName;
                                                }
                                            );
                                            [void]$users.Add($member);
                                        }
                                    }
                                }
                            }
                            #Check if transitive members had service principals
                            $transitiveSps = @($users).Where({$_.'@odata.type' -match '#microsoft.graph.servicePrincipal'})
                            If($transitiveSps.Count -gt 0){
                                ForEach($sp in $transitiveSps){
                                    [void]$servicePrincipals.Add($sp)
                                }
                            }
                            #Get all users
                            $allUsers = (@($users).Where({$_.'@odata.type' -match '#microsoft.graph.user'}))
                            #Get duplicate users
                            $allduplicatedUsers = [System.Collections.Generic.List[System.Object]]::new();
                            If($allUsers.Count -gt 0){
                                $duplicateUsers = Get-MonkeyDuplicateObjectsByProperty -ReferenceObject $allUsers -Property Id
                                ForEach($user in @($duplicateUsers)){
                                    [void]$allduplicatedUsers.Add($user);
                                }
                            }
                            $roleObject.duplicateUsers = $allduplicatedUsers;
                            #Populate object
                            $roleObject.servicePrincipals = $servicePrincipals;
                            #Get effective users and remove duplicate members
                            $alluniqueUsers = @($users).Where({$_.'@odata.type' -match '#microsoft.graph.user'}) | Sort-Object -Property Id -Unique -ErrorAction Ignore
                            If($null -eq $alluniqueUsers){
                                $alluniqueUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                            }
                            $roleObject.effectiveUsers = $alluniqueUsers;
                            #Add effectiveMembers to object
                            $roleObject.effectiveMembers = $roleObject.servicePrincipals + $roleObject.effectiveUsers;
                            #Count objects
                            $roleObject.totalActiveMembers = ($roleObject.servicePrincipals.Count + $roleObject.effectiveUsers.Count)
                            #Count objects
                            $roleObject.totalActiveusers = $roleObject.effectiveUsers.Count;
                            #Calculate duplicated route
                            If($roleObject.duplicateUsers.Count -gt 0){
                                $myIds = Compare-Object -ReferenceObject $roleObject.duplicateUsers -DifferenceObject $nestedMembers -Property Id -IncludeEqual | Where-Object {$_.sideIndicator -eq '=='} | Select-Object -ExpandProperty Id
                                $nestedObjects = $nestedMembers.Where({$_.id -in $myIds}) | Sort-Object -Property Id -Unique
                                If($nestedObjects){
                                    ForEach($obj in @($nestedObjects)){
                                        [void]$allnestedObjects.Add($obj);
                                    }
                                }
                            }
                            $roleObject.duplicateObjects = $allnestedObjects;
                            #Add to array
                            [void]$allRoleAssignments.Add($roleObject);
                        }
                    }
                    Write-Output $allRoleAssignments -NoEnumerate
                    break
                }
            }
        }
    }
    End{
        #Nothing to do here
    }
}
