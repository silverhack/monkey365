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

Function Get-MonkeyAzCosmosDBRoleAssignment {
    <#
        .SYNOPSIS
		Get CosmosDB role assignment

        .DESCRIPTION
		Get CosmosDB role assignment

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzCosmosDBRoleAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
	[CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="CosmosDB object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-11-01-preview"
    )
    Process{
        #Set null
        $roleDefinitions = $roleAssignments = $null;
        #Set arrays
        $allRoleDefinitions = [System.Collections.Generic.List[System.Object]]::new();
        $allRoleAssignments = [System.Collections.Generic.List[System.Object]]::new();
        Try{
            $api_Version = $O365Object.internal_config.entraId.provider.msgraph.api_version
        }
        Catch{
            $api_Version = "v1.0"
        }
        #Get role definitions
        $p = @{
	        Id = $InputObject.Id;
            Resource = "sqlRoleDefinitions";
            ApiVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $roleDefinitions = Get-MonkeyAzObjectById @p
        #Get role assignments
        $p = @{
	        Id = $InputObject.Id;
            Resource = "sqlRoleAssignments";
            ApiVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $roleAssignments = Get-MonkeyAzObjectById @p
        Try{
            If($null -ne $roleDefinitions -and $null -ne $roleAssignments){
                ForEach($roleDefinition in @($roleDefinitions)){
                    $obj = [PsCustomObject]@{
                        id = $roleDefinition.id;
                        internalName = $roleDefinition.name;
                        roleName = $roleDefinition.properties.roleName;
                        type = $roleDefinition.properties.type;
                        assignableScopes = $roleDefinition.properties.assignableScopes;
                        permissions = $roleDefinition.properties.permissions;
                    }
                    #Add to array
                    [void]$allRoleDefinitions.Add($obj)
                }
                #Map objects
                $mappedRoleAssignments = $roleAssignments | Group-Object -Property {$_.properties.roleDefinitionId}
                ForEach($assignments in @($mappedRoleAssignments).GetEnumerator()){
                    #Get Role
                    $role = $allRoleDefinitions.Where({$_.id -eq $assignments.Name});
                    If($role.Count -gt 0){
                        $msg = @{
			                MessageData = ("Getting {0} members from {1}" -f $role[0].RoleName, $InputObject.name);
			                callStack = (Get-PSCallStack | Select-Object -First 1);
			                logLevel = 'info';
			                InformationAction = $O365Object.InformationAction;
			                Tags = @('CosmosDBRBACInfo');
		                }
		                Write-Information @msg
                        #Create role object
                        $roleObject = $role | New-MonkeyCosmosDBRoleObject
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
                        If($allUsers.Count -gt 0){
                            $duplicateUsers = Get-MonkeyDuplicateObjectsByProperty -ReferenceObject $allUsers -Property Id
                            ForEach($user in @($duplicateUsers)){
                                [void]$roleObject.duplicateUsers.Add($user);
                            }
                        }
                        #Populate object
                        $roleObject.servicePrincipals = $servicePrincipals;
                        #Get effective users and remove duplicate members
                        $uniqueUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                        $alluniqueUsers = @($users).Where({$_.'@odata.type' -match '#microsoft.graph.user'}) | Sort-Object -Property Id -Unique -ErrorAction Ignore
                        If($null -ne $alluniqueUsers){
                            foreach($usr in @($alluniqueUsers)){
                                [void]$uniqueUsers.Add($usr);
                            }
                        }
                        $roleObject.effectiveUsers = $uniqueUsers;
                        #Add effectiveMembers to object
                        $roleObject.effectiveMembers = $roleObject.servicePrincipals + $roleObject.effectiveUsers;
                        #Count objects
                        $roleObject.totalActiveMembers = ($roleObject.servicePrincipals.Count + $roleObject.effectiveUsers.Count)
                        #Count objects
                        $roleObject.totalActiveusers = $roleObject.effectiveUsers.Count;
                        #Add to array
                        [void]$allRoleAssignments.Add($roleObject);
                    }
                }
            }
            Write-Output $allRoleAssignments -NoEnumerate
        }
        Catch{
            Write-Error $_
            Write-Output $allRoleAssignments -NoEnumerate
        }
    }
}
