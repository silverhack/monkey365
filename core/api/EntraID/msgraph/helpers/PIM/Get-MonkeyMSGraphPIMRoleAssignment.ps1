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


Function Get-MonkeyMSGraphPIMRoleAssignment{
    <#
        .SYNOPSIS
		Get PIM role assignments

        .DESCRIPTION
		Get PIM role assignments

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphPIMRoleAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PsObject]])]
    Param ()
    try{
        $new_arg = @{
            APIVersion = 'beta';
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
            If($O365Object.useOldAADAPIForUsers){
                If($O365Object.canRequestMFAForUsers){
                    $jobParam = @{
	                    ScriptBlock = { Get-MonkeyGraphAADUser -UserId $_ };
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
        #Set generic list
        $allroleAssignments = [System.Collections.Generic.List[System.Management.Automation.PsObject]]::new()
        #Get PIM role assignments
        $msg = @{
			MessageData = "Getting Role management policy from PIM";
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDPIMInfo');
		}
		Write-Information @msg
        $policyAssignments = Get-MonkeyMSGraphPIMRoleManagementPolicyAssignment
        #Get role templates
        $msg = @{
			MessageData = "Getting Role templates from PIM";
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDPIMInfo');
		}
		Write-Information @msg
        $roleTemplates = Get-MonkeyMSGraphDirectoryRoleTemplate
        #Get all policies
        $p = @{
	        ScriptBlock = { Get-MonkeyMSGraphPIMRoleManagementPolicy -InputObject $_.policyId };
	        Runspacepool = $O365Object.monkey_runspacePool;
	        ReuseRunspacePool = $true;
	        Debug = $O365Object.VerboseOptions.Debug;
	        Verbose = $O365Object.VerboseOptions.Verbose;
	        MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	        BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	        BatchSize = $O365Object.nestedRunspaces.BatchSize;
        }
        @($policyAssignments).ForEach(
            {
                $policy = $_;
                $settings = $policy | Invoke-MonkeyJob @p
                $policy | Add-Member -MemberType NoteProperty -Name settings -Value $settings
                #Get role
                $role = @($roleTemplates).Where({$_.id -eq $policy.roleDefinitionId})
                if($role.Count -gt 0){
                    $roleObject = $role | New-MonkeyPIMRoleObject
                    $roleObject.policy = $policy;
                    [void]$allroleAssignments.Add($roleObject);
                }
                Start-Sleep -Milliseconds 500;
            }
        );
        #Get Active role assignment
        $msg = @{
			MessageData = "Getting active role assignments from PIM";
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDPIMInfo');
		}
		Write-Information @msg
        $activeRoleAssignments = Get-MonkeyMSGraphPIMActiveRoleAssignment
        #Group objects
        $active_objects = $activeRoleAssignments | Group-Object -Property roleDefinitionId
        foreach($activeRole in $active_objects){
            #Get the role
            $myRole = $allroleAssignments.Where({$_.id -eq $activeRole.Name}) | Select-Object -First 1
            If($null -ne $myRole){
                $msg = @{
			        MessageData = ("Getting active role assignments for {0}" -f $myRole.Name);
			        callStack = (Get-PSCallStack | Select-Object -First 1);
			        logLevel = 'info';
			        InformationAction = $O365Object.InformationAction;
			        Tags = @('EntraIDPIMInfo');
		        }
		        Write-Information @msg
                #update object
                $myRole.activeAssignment.isUsed = $true;
                $myRole.roleInUse = $true;
                $activeMembers = $activeRole.Group | Select-Object principalId,startDateTime,endDateTime,assignmentType,memberType -ErrorAction Ignore
                if($null -ne $activeMembers){
                    #Set array
                    $allUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    $allServicePrincipals = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    #Get ids
                    $ids = $activeMembers | Select-Object -ExpandProperty principalId
                    $identities = Get-MonkeyMSGraphDirectoryObjectById -Ids $ids
                    #Get groups
                    $groups = @($identities).Where({$_.'@odata.type' -match '#microsoft.graph.group'})
                    #Get users
                    $users = @($identities).Where({$_.'@odata.type' -match '#microsoft.graph.user'})
                    #Get service Principals
                    $allSP = @($identities).Where({$_.'@odata.type' -match '#microsoft.graph.servicePrincipal'})
                    #get Real members
                    foreach($grp in $groups){
                        $objMetadata = @($activeMembers).Where({$_.principalId -eq $grp.id}) | Select-Object * -First 1 -ErrorAction Ignore
                        $groupMember = Get-MonkeyMSGraphGroupTransitiveMember -GroupId $grp.id -Parents @($grp.id)
                        if($groupMember){
                            $ids = @($groupMember).Where({$_.'@odata.type' -match '#microsoft.graph.user'}) | Select-Object -ExpandProperty Id
                            #Invoke job
                            $members = $ids | Invoke-MonkeyJob @jobParam
                            if($members){
                                foreach($member in @($members)){
                                    if($null -ne $objMetadata){
                                        $member | Add-Member -MemberType NoteProperty -Name startDateTime -Value $objMetadata.startDateTime
                                        $member | Add-Member -MemberType NoteProperty -Name endDateTime -Value $objMetadata.endDateTime
                                        $member | Add-Member -MemberType NoteProperty -Name assignmentType -Value $objMetadata.assignmentType
                                        $member | Add-Member -MemberType NoteProperty -Name memberType -Value $objMetadata.memberType
                                    }
                                    [void]$allUsers.Add($member)
                                }
                            }
                            #Get Service Principals
                            $sps = @($groupMember).Where({$_.'@odata.type' -match '#microsoft.graph.servicePrincipal'})
                            foreach($sp in $sps){
                                if($null -ne $objMetadata){
                                    $sp | Add-Member -MemberType NoteProperty -Name startDateTime -Value $objMetadata.startDateTime
                                    $sp | Add-Member -MemberType NoteProperty -Name endDateTime -Value $objMetadata.endDateTime
                                    $sp | Add-Member -MemberType NoteProperty -Name assignmentType -Value $objMetadata.assignmentType
                                    $sp | Add-Member -MemberType NoteProperty -Name memberType -Value $objMetadata.memberType
                                }
                                [void]$allServicePrincipals.Add($sp);
                            }
                        }
                    }
                    #Add users
                    $ids = $users| Select-Object -ExpandProperty Id
                    #Invoke job
                    $members = $ids | Invoke-MonkeyJob @jobParam
                    if($null -ne $members){
                        foreach($member in @($members)){
                            $objMetadata = @($activeMembers).Where({$_.principalId -eq $member.id}) | Select-Object * -First 1 -ErrorAction Ignore
                            if($null -ne $objMetadata){
                                $member | Add-Member -MemberType NoteProperty -Name startDateTime -Value $objMetadata.startDateTime
                                $member | Add-Member -MemberType NoteProperty -Name endDateTime -Value $objMetadata.endDateTime
                                $member | Add-Member -MemberType NoteProperty -Name assignmentType -Value $objMetadata.assignmentType
                                $member | Add-Member -MemberType NoteProperty -Name memberType -Value $objMetadata.memberType
                            }
                            [void]$allUsers.Add($member)
                        }
                    }
                    #Populate Service principals
                    foreach($sp in @($allSP)){
                        $objMetadata = @($activeMembers).Where({$_.principalId -eq $sp.id}) | Select-Object * -First 1 -ErrorAction Ignore
                        if($null -ne $objMetadata){
                            $sp | Add-Member -MemberType NoteProperty -Name startDateTime -Value $objMetadata.startDateTime
                            $sp | Add-Member -MemberType NoteProperty -Name endDateTime -Value $objMetadata.endDateTime
                            $sp | Add-Member -MemberType NoteProperty -Name assignmentType -Value $objMetadata.assignmentType
                            $sp | Add-Member -MemberType NoteProperty -Name memberType -Value $objMetadata.memberType
                        }
                        [void]$allServicePrincipals.Add($sp)
                    }
                    #Populate Groups
                    $myRole.activeAssignment.groups = $groups;
                    #Get effective users and remove duplicate members
                    $uniqueUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    $alluniqueUsers = $allUsers | Sort-Object -Property Id -Unique -ErrorAction Ignore
                    if($null -ne $alluniqueUsers){
                        foreach($usr in @($alluniqueUsers)){
                            [void]$uniqueUsers.Add($usr);
                        }
                    }
                    #Populate members
                    $myRole.activeAssignment.users = $uniqueUsers;
                    #Populate Service Principals
                    $myRole.activeAssignment.servicePrincipals = $allServicePrincipals;
                    #Count objects
                    $myRole.activeAssignment.totalActiveMembers = ($myRole.activeAssignment.users.Count + $myRole.activeAssignment.servicePrincipals.Count)
                    #Get duplicate users
                    if($allUsers.Count -gt 0){
                        $myRole.activeAssignment.duplicateUsers = Get-MonkeyDuplicateObjectsByProperty -ReferenceObject $allUsers -Property Id
                    }
                    Else{
                        #Set empty collection
                        $myRole.activeAssignment.duplicateUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    }
                }
                Else{
                    $myRole.activeAssignment.totalActiveMembers = 0;
                    $myRole.activeAssignment.duplicateUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                }
            }
        }
        #Get eligible assignments
        $msg = @{
			MessageData = "Getting eligible role assignments from PIM";
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDPIMInfo');
		}
		Write-Information @msg
        $eligibleRoleAssignments = Get-MonkeyMSGraphPIMEligibleRoleAssignment
        #Group objects
        $eligible_objects = $eligibleRoleAssignments | Group-Object -Property roleDefinitionId
        foreach($eligibleRole in $eligible_objects){
            #Get the role
            $myRole = $allroleAssignments.Where({$_.id -eq $eligibleRole.Name}) | Select-Object -First 1
            If($null -ne $myRole){
                $msg = @{
			        MessageData = ("Getting eligible role assignments for {0}" -f $myRole.Name);
			        callStack = (Get-PSCallStack | Select-Object -First 1);
			        logLevel = 'info';
			        InformationAction = $O365Object.InformationAction;
			        Tags = @('EntraIDPIMInfo');
		        }
		        Write-Information @msg
                #update object
                $myRole.eligibleAssignment.isUsed = $true;
                $myRole.roleInUse = $true;
                #$ids = $eligibleRole.Group | Select-Object -ExpandProperty principalId -ErrorAction Ignore
                $eligibleMembers = $eligibleRole.Group | Select-Object principalId,startDateTime,endDateTime,assignmentType,memberType -ErrorAction Ignore
                If($null -ne $eligibleMembers){
                    #Set array
                    $allUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    $allServicePrincipals = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    #Get ids
                    $ids = $eligibleMembers | Select-Object -ExpandProperty principalId
                    $identities = Get-MonkeyMSGraphDirectoryObjectById -Ids $ids
                    #Get groups
                    $groups = @($identities).Where({$_.'@odata.type' -match '#microsoft.graph.group'})
                    #Get users
                    $users = @($identities).Where({$_.'@odata.type' -match '#microsoft.graph.user'})
                    #Get service Principals
                    $allSP = @($identities).Where({$_.'@odata.type' -match '#microsoft.graph.servicePrincipal'})
                    #get Real members
                    foreach($grp in $groups){
                        $objMetadata = @($eligibleMembers).Where({$_.principalId -eq $grp.id}) | Select-Object * -First 1 -ErrorAction Ignore
                        $groupMember = Get-MonkeyMSGraphGroupTransitiveMember -GroupId $grp.id -Parents @($grp.id)
                        if($groupMember){
                            $ids = @($groupMember).Where({$_.'@odata.type' -match '#microsoft.graph.user'}) | Select-Object -ExpandProperty Id
                            #Invoke job
                            $members = $ids | Invoke-MonkeyJob @jobParam
                            if($members){
                                foreach($member in @($members)){
                                    if($null -ne $objMetadata){
                                        $member | Add-Member -MemberType NoteProperty -Name startDateTime -Value $objMetadata.startDateTime
                                        $member | Add-Member -MemberType NoteProperty -Name endDateTime -Value $objMetadata.endDateTime
                                        $member | Add-Member -MemberType NoteProperty -Name assignmentType -Value $objMetadata.assignmentType
                                        $member | Add-Member -MemberType NoteProperty -Name memberType -Value $objMetadata.memberType
                                    }
                                    [void]$allUsers.Add($member)
                                }
                            }
                            #Get Service Principals
                            $sps = @($groupMember).Where({$_.'@odata.type' -match '#microsoft.graph.servicePrincipal'})
                            foreach($sp in $sps){
                                if($null -ne $objMetadata){
                                    $sp | Add-Member -MemberType NoteProperty -Name startDateTime -Value $objMetadata.startDateTime
                                    $sp | Add-Member -MemberType NoteProperty -Name endDateTime -Value $objMetadata.endDateTime
                                    $sp | Add-Member -MemberType NoteProperty -Name assignmentType -Value $objMetadata.assignmentType
                                    $sp | Add-Member -MemberType NoteProperty -Name memberType -Value $objMetadata.memberType
                                }
                                [void]$allServicePrincipals.Add($sp);
                            }
                        }
                    }
                    #Add users
                    $ids = $users| Select-Object -ExpandProperty Id
                    #Invoke job
                    $members = $ids | Invoke-MonkeyJob @jobParam
                    if($null -ne $members){
                        foreach($member in @($members)){
                            $objMetadata = @($eligibleMembers).Where({$_.principalId -eq $member.id}) | Select-Object * -First 1 -ErrorAction Ignore
                            if($null -ne $objMetadata){
                                $member | Add-Member -MemberType NoteProperty -Name startDateTime -Value $objMetadata.startDateTime
                                $member | Add-Member -MemberType NoteProperty -Name endDateTime -Value $objMetadata.endDateTime
                                $member | Add-Member -MemberType NoteProperty -Name assignmentType -Value $objMetadata.assignmentType
                                $member | Add-Member -MemberType NoteProperty -Name memberType -Value $objMetadata.memberType
                            }
                            [void]$allUsers.Add($member)
                        }
                    }
                    #Populate Service principals
                    foreach($sp in @($allSP)){
                        $objMetadata = @($eligibleMembers).Where({$_.principalId -eq $sp.id}) | Select-Object * -First 1 -ErrorAction Ignore
                        if($null -ne $objMetadata){
                            $sp | Add-Member -MemberType NoteProperty -Name startDateTime -Value $objMetadata.startDateTime
                            $sp | Add-Member -MemberType NoteProperty -Name endDateTime -Value $objMetadata.endDateTime
                            $sp | Add-Member -MemberType NoteProperty -Name assignmentType -Value $objMetadata.assignmentType
                            $sp | Add-Member -MemberType NoteProperty -Name memberType -Value $objMetadata.memberType
                        }
                        [void]$allServicePrincipals.Add($sp)
                    }
                    #Populate Groups
                    $myRole.eligibleAssignment.groups = $groups;
                    #Get effective users and remove duplicate members
                    $uniqueUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    $alluniqueUsers = $allUsers | Sort-Object -Property Id -Unique -ErrorAction Ignore
                    if($null -ne $alluniqueUsers){
                        foreach($usr in @($alluniqueUsers)){
                            [void]$uniqueUsers.Add($usr);
                        }
                    }
                    #Populate members
                    $myRole.eligibleAssignment.users = $uniqueUsers;
                    #Populate Service Principals
                    $myRole.eligibleAssignment.servicePrincipals = $allServicePrincipals;
                    #Count objects
                    $myRole.eligibleAssignment.totalEligibleMembers = ($myRole.eligibleAssignment.users.Count + $myRole.eligibleAssignment.servicePrincipals.Count)
                    #Get duplicate users
                    if($allUsers.Count -gt 0){
                        $myRole.eligibleAssignment.duplicateUsers = Get-MonkeyDuplicateObjectsByProperty -ReferenceObject $allUsers -Property Id
                    }
                    Else{
                        #Set empty collection
                        $myRole.eligibleAssignment.duplicateUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    }
                }
                Else{
                    $myRole.eligibleAssignment.totalEligibleMembers = 0;
                    $myRole.eligibleAssignment.duplicateUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                }
                #Calculate eligible and active members
                $myRole.totalMembers = $myRole.eligibleAssignment.totalEligibleMembers + $myRole.activeAssignment.totalActiveMembers
            }
        }
        #return data
        $allroleAssignments
    }
    Catch{
        $msg = @{
			MessageData = $_;
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'verbose';
			InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
			Tags = @('EntraIDPIMError');
		}
		Write-Verbose @msg
    }
}
