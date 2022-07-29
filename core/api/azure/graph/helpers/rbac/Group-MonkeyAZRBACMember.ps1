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


Function Group-MonkeyAZRBACMember{
    <#
        .SYNOPSIS
		Associate RBAC information to users

        .DESCRIPTION
		Associate RBAC information to users

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Group-MonkeyAZRBACMember
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$role_assignments
    )
    Begin{
        $use_azure_portal = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.useAzurePortalAPI)
        $dump_users_with_graph_api = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.dumpAdUsersWithInternalGraphAPI)
        #Set Job params
        $vars = @{
            "O365Object"=$O365Object;
            "WriteLog"=$O365Object.WriteLog;
            'Verbosity' = $O365Object.VerboseOptions;
            'InformationAction' = $O365Object.InformationAction;
        }
        $Jobparam = @{
            ScriptBlock = $null;
            ImportCommands = $O365Object.LibUtils;
            ImportVariables = $vars;
            ImportModules = $O365Object.runspaces_modules;
            StartUpScripts = $O365Object.runspace_init;
            ThrowOnRunspaceOpenError = $true;
            Debug = $O365Object.VerboseOptions.Debug;
            Verbose = $O365Object.VerboseOptions.Verbose;
            Throttle = $O365Object.nestedRunspaceMaxThreads;
            MaxQueue = $O365Object.MaxQueue;
            BatchSleep = $O365Object.BatchSleep;
            BatchSize = $O365Object.BatchSize;
        }
        #Set array
        $az_role_assignments = @()
    }
    Process{
        #Normalize data
        foreach($role in $role_assignments){
            $all_members = New-Object System.Collections.Generic.List[System.Object]
            $all_apps = New-Object System.Collections.Generic.List[System.Object]
            $msg = @{
                MessageData = ($message.RoleBasedGetUsersMessage -f $role.properties.roleName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRBACUsers');
            }
            Write-Debug @msg
            foreach($member in $role.members){
                if($member.principalType -eq "User"){
                    #Add fields
                    $member | Add-Member -type NoteProperty -name objectType -value $member.principalType
                    $member | Add-Member -type NoteProperty -name ObjectId -value $member.principalId
                    #Get Detailed User
                    $tmp_user = $null
                    if($dump_users_with_graph_api){
                        #Get user
                        $tmp_user = Get-AADDetailedUser -user $member
                    }
                    elseif(-NOT $dump_users_with_graph_api -AND $use_azure_portal -and $O365Object.isConfidentialApp -eq $false){
                        #Get internal function
                        $tmp_user = Get-MonkeyADPortalDetailedUser -user $member
                    }
                    else{
                        #Get internal function
                        $tmp_user = Get-AADDetailedUser -user $member
                    }
                    if($tmp_user){
                        [void]$all_members.Add($tmp_user)
                    }
                }
                elseif($member.principalType -ne "Group" -AND $member.principalType -ne "User"){
                    $raw_app = Get-MonkeyADObjectByObjectId -ObjectId $member.principalId
                    [void]$all_apps.Add($raw_app)
                }
                elseif($member.principalType -eq "Group"){
                    $msg = @{
                        MessageData = ($message.GroupWithRoleMessage -f $member.principalId, $role.properties.roleName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureRbacGroupMember');
                    }
                    Write-Debug @msg
                    #Get group members
                    $group_members = Get-MonkeyAZGroupMember -GroupId $member.principalId
                    if($group_members){
                        #Get real users
                        if($dump_users_with_graph_api){
                            $Jobparam.ScriptBlock = {Get-AADDetailedUser -user $_}
                        }
                        elseif(-NOT $dump_users_with_graph_api -AND $use_azure_portal -and $O365Object.isConfidentialApp -eq $false){
                            #Get internal function
                            $Jobparam.ScriptBlock = {Get-MonkeyADPortalDetailedUser -user $_}
                        }
                        else{
                            #Get internal function
                            $Jobparam.ScriptBlock = {Get-AADDetailedUser -user $_}
                        }
                        if($null -ne $Jobparam.ScriptBlock){
                            #Get Users
                            $new_members = $group_members | Invoke-MonkeyJob @Jobparam
                            if($new_members){
                                foreach($member in @($new_members)){
                                    [void]$all_members.Add($member)
                                }
                            }
                        }
                    }
                }
            }
            #Set new object
            $az_role_assignments += New-Object PSObject -property $([ordered]@{
                RoleName = $role.properties.roleName;
                RoleDescription = $role.properties.description;
                RoleType = $role.properties.type;
                RoleId = $role.name;
                RawRole = $role;
                CreatedOn = $role.properties.createdOn;
                updatedOn  = $role.properties.updatedOn;
                permissions = $role.properties.permissions;
                users = $all_members.ToArray();
                applications = $all_apps.ToArray();
            })
        }
    }
    End{
        return $az_role_assignments
    }
}