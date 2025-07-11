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

Function Get-MonkeyMSGraphEntraRoleAssignment {
    <#
        .SYNOPSIS
		Get Entra ID role assignment

        .DESCRIPTION
		Get Entra ID role assignment

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphEntraRoleAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
	[CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
	Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        #Set generic list
        $allEntraIDRoleAssignment = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        #Set nulls
        $role_assignments = $role_definitions = $null;
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $new_arg = @{
            APIVersion = $APIVersion;
        }
        #Set Job params
        If($O365Object.isConfidentialApp){
            $jobParam = @{
	            ScriptBlock = { Get-MonkeyMsGraphMFAUserDetail -UserId $_};
                Arguments = $new_arg;
	            Runspacepool = $O365Object.monkey_runspacePool;
	            ReuseRunspacePool = $true;
	            Debug = $O365Object.VerboseOptions.Debug;
	            Verbose = $O365Object.VerboseOptions.Verbose;
	            MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	            BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	            BatchSize = $O365Object.nestedRunspaces.BatchSize;
            }
        }
        Else{
            If($O365Object.auth_tokens.MSGraph.clientId -eq (Get-WellKnownAzureService -AzureService MicrosoftGraph)){
                #Set job params
                $jobParam = @{
	                ScriptBlock = { Get-MonkeyMsGraphMFAUserDetail -UserId $_};
                    Arguments = $new_arg;
	                Runspacepool = $O365Object.monkey_runspacePool;
	                ReuseRunspacePool = $true;
	                Debug = $O365Object.VerboseOptions.Debug;
	                Verbose = $O365Object.VerboseOptions.Verbose;
	                MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	                BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	                BatchSize = $O365Object.nestedRunspaces.BatchSize;
                }
            }
            Else{
                #Set job params
                $jobParam = @{
	                ScriptBlock = { Get-MonkeyMSGraphUser -UserId $_ -BypassMFACheck};
                    Arguments = $new_arg;
	                Runspacepool = $O365Object.monkey_runspacePool;
	                ReuseRunspacePool = $true;
	                Debug = $O365Object.VerboseOptions.Debug;
	                Verbose = $O365Object.VerboseOptions.Verbose;
	                MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	                BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	                BatchSize = $O365Object.nestedRunspaces.BatchSize;
                }
            }
        }
    }
    Process{
        $p = @{
	        Authentication = $graphAuth;
	        ObjectType = "roleManagement/directory/roleAssignments";
	        Environment = $Environment;
            Expand = 'Principal';
	        ContentType = 'application/json';
	        Method = "GET";
	        APIVersion = "v1.0";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $role_assignments = Get-MonkeyMSGraphObject @p
        #Get Roles and expand the roleDefinition attribute
        $p.Expand = 'roleDefinition';
        $role_definitions = Get-MonkeyMSGraphObject @p
    }
    End{
        Try{
            If($null -ne $role_assignments -and $null -ne $role_definitions){
                $groupAssignments = $role_assignments | Group-Object -Property roleDefinitionId
                foreach($assignment in $groupAssignments){
                    $roleAssignment =  $role_definitions.Where({$_.roleDefinitionId -eq $assignment.Name},[System.Management.Automation.WhereOperatorSelectionMode]::First)
                    $roleObject = $roleAssignment | New-MonkeyEntraIDRoleObject
                    #get Members
                    $allMembers = $assignment.Group.principal
                    #Get users
                    $roleObject.users = @($allMembers).Where({$_.'@odata.type' -match '#microsoft.graph.user'})
                    #Get groups
                    $roleObject.groups = @($allMembers).Where({$_.'@odata.type' -match '#microsoft.graph.group'})
                    #Get users
                    $users = @($allMembers).Where({$_.'@odata.type' -match '#microsoft.graph.user'})
                    If($roleObject.groups.Count -gt 0){
                        #get Real members
                        foreach($grp in $roleObject.groups){
                            $groupMember = Get-MonkeyMSGraphGroupTransitiveMember -GroupId $grp.id -Parents @($grp.id) -APIVersion $APIVersion
                            if($groupMember){
                                foreach($member in $groupMember){
                                    [void]$users.Add($member);
                                }
                            }
                        }
                    }
                    #Get effective users and remove duplicate members
                    $uniqueUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    $extendedUniqueUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    $alluniqueUsers = @($users).Where({$_.'@odata.type' -match '#microsoft.graph.user'}) | Sort-Object -Property Id -Unique -ErrorAction Ignore
                    if($null -ne $alluniqueUsers){
                        foreach($usr in @($alluniqueUsers)){
                            [void]$uniqueUsers.Add($usr);
                        }
                    }
                    #Get user's id
                    $allIds = $uniqueUsers | Select-Object -ExpandProperty Id -ErrorAction Ignore
                    If (@($allIds).Count -gt 0){
                        #Invoke job
                        $members = $allIds | Invoke-MonkeyJob @jobParam
                        If($null -ne $members -and @($members).Count -gt 0){
                            foreach($member in @($members)){
                                [void]$extendedUniqueUsers.Add($member);
                            }
                        }
                    }
                    $roleObject.effectiveUsers = $extendedUniqueUsers;
                    #Get servicePrincipals
                    $servicePrincipals = @($allMembers).Where({$_.'@odata.type' -match '#microsoft.graph.servicePrincipal'})
                    #Check if transitive members had service principals
                    $transitiveSps = @($users).Where({$_.'@odata.type' -match '#microsoft.graph.servicePrincipal'})
                    foreach($sp in $transitiveSps){
                        [void]$servicePrincipals.Add($sp)
                    }
                    #Add Serviceprincipals to object
                    $roleObject.servicePrincipals = $servicePrincipals;
                    #Count objects
                    $roleObject.totalActiveusers = $roleObject.effectiveUsers.Count;
                    #Get duplicate users
                    $allUsers = (@($users).Where({$_.'@odata.type' -match '#microsoft.graph.user'}))
                    if($allUsers.Count -gt 0){
                        $roleObject.duplicateUsers = Get-MonkeyDuplicateObjectsByProperty -ReferenceObject $allUsers -Property Id
                    }
                    Else{
                        #Set empty collection
                        $roleObject.duplicateUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    }
                    #Add effectiveMembers to object
                    $roleObject.effectiveMembers = $roleObject.servicePrincipals + $roleObject.effectiveUsers;
                    #Count objects
                    $roleObject.totalActiveMembers = ($roleObject.servicePrincipals.Count + $roleObject.effectiveUsers.Count)
                    #Add to list
                    [void]$allEntraIDRoleAssignment.Add($roleObject)
                }
            }
            Write-Output $allEntraIDRoleAssignment -NoEnumerate
        }
        Catch{
            write-host $_
            Write-Error $_
            return , $allEntraIDRoleAssignment
        }
    }
}
