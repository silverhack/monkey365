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


Function Invoke-MonkeyPrivilegedIdentityInfo{
    <#
        .SYNOPSIS
		Get information about eligible and active assignments from PIM

        .DESCRIPTION
		Get information about eligible and active assignments from PIM

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyPrivilegedIdentityInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    Try{
        $msg = @{
			MessageData = "Getting active roles from PIM";
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDPIMInfo');
		}
		Write-Information @msg
        $p = @{
	        InformationAction = $O365Object.InformationAction;
	        Verbose = $O365Object.Verbose;
	        Debug = $O365Object.Debug;
        }
        $role_definition = Get-MonkeyMSPIMRoleDefinition @p
        $activeRoles = @($role_definition).Where({ $_.eligibleAssignmentCount -gt 0 -or $_.activeAssignmentCount -gt 0 })
        foreach ($role in $activeRoles) {
            $role | Add-Member -Type NoteProperty -name eligibleAssignment -value ([System.Collections.Generic.List[System.Object]]::new()) -Force
            $role | Add-Member -Type NoteProperty -name activeAssignment -value ([System.Collections.Generic.List[System.Object]]::new()) -Force
            if($role.eligibleAssignmentCount -gt 0){
                $p = @{
		            RoleDefinitionId = $role.templateId;
		            AssignmentType = 'Eligible';
		            InformationAction = $O365Object.InformationAction;
		            Verbose = $O365Object.Verbose;
		            Debug = $O365Object.Debug;
	            }
	            $eligible_roles = Get-MonkeyMSPIMRoleAssignment @p
                if ($eligible_roles) {
                    $all_eligible_ra = New-Object System.Collections.Generic.List[System.Object]
		            foreach ($erole in $eligible_roles) {
			            #Add to list
			            [void]$all_eligible_ra.Add($erole)
		            }
                    $role | Add-Member -Type NoteProperty -name eligibleAssignment -value $all_eligible_ra -Force
	            }
            }
            If($role.activeAssignmentCount -gt 0){
                $p = @{
		            RoleDefinitionId = $role.templateId;
		            AssignmentType = 'Active';
		            InformationAction = $O365Object.InformationAction;
		            Verbose = $O365Object.Verbose;
		            Debug = $O365Object.Debug;
	            }
	            $active_roles = Get-MonkeyMSPIMRoleAssignment @p
                if ($active_roles) {
                    $all_active_ra = New-Object System.Collections.Generic.List[System.Object]
		            foreach ($arole in $active_roles) {
			            [void]$all_active_ra.Add($arole)
		            }
                    $role | Add-Member -Type NoteProperty -name activeAssignment -value $all_active_ra -Force
	            }
            }
            #Add effective members
            $effectiveMembers = New-Object System.Collections.Generic.List[System.Object]
            if($role.activeAssignment.Count -gt 0){
                foreach($member in $role.activeAssignment){
                    if($member.subject.type -eq 'Group'){
                        $msg = @{
			                MessageData = ("Group found in active assignment for {0}. Getting members" -f $member.roleDefinition.displayName);
			                callStack = (Get-PSCallStack | Select-Object -First 1);
			                logLevel = 'verbose';
			                InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
			                Tags = @('EntraIDPIMInfo');
		                }
		                Write-Verbose @msg
                        $p = @{
		                    GroupId = $member.subject.id
		                    Parents = @($member.subject.id);
		                    InformationAction = $O365Object.InformationAction;
		                    Verbose = $O365Object.Verbose;
		                    Debug = $O365Object.Debug;
	                    }
	                    $group_members = Get-MonkeyMSGraphGroupTransitiveMember @p
                        if($group_members){
                            foreach($gmember in $group_members){
                                [void]$effectiveMembers.Add($gmember)
                            }
                        }
                    }
                    else{
                        [void]$effectiveMembers.Add($member)
                    }
                }
            }
            if($role.eligibleAssignment.Count -gt 0){
                foreach($member in $role.eligibleAssignment){
                    if($member.subject.type -eq 'Group'){
                        $msg = @{
			                MessageData = ("Group found in eligible assignment for {0}. Getting members" -f $member.roleDefinition.displayName);
			                callStack = (Get-PSCallStack | Select-Object -First 1);
			                logLevel = 'verbose';
			                InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
			                Tags = @('EntraIDPIMInfo');
		                }
		                Write-Verbose @msg
                        $p = @{
		                    GroupId = $member.subject.id
		                    Parents = @($member.subject.id);
		                    InformationAction = $O365Object.InformationAction;
		                    Verbose = $O365Object.Verbose;
		                    Debug = $O365Object.Debug;
	                    }
	                    $group_members = Get-MonkeyMSGraphGroupTransitiveMember @p
                        if($group_members){
                            foreach($gmember in $group_members){
                                [void]$effectiveMembers.Add($gmember)
                            }
                        }
                    }
                    else{
                        [void]$effectiveMembers.Add($member)
                    }
                }
            }
            $role | Add-Member -Type NoteProperty -name effectiveAssignment -value $effectiveMembers -Force
            $role | Add-Member -Type NoteProperty -name effectiveAssignmentCount -value $effectiveMembers.Count -Force
        }
        #return active roles
        return $activeRoles
    }
    Catch{
        Write-Error $_
    }
}


