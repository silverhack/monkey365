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


Function Group-MonkeyGraphAADRBACMember{
    <#
        .SYNOPSIS
		Associate Azure AD RBAC information to users

        .DESCRIPTION
		Associate Azure AD RBAC information to users

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Group-MonkeyGraphAADRBACMember
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$role_assignments
    )
    Begin{
        #Get libs for runspace
        $rsOptions = Initialize-MonkeyScan -Provider EntraID
        #Get vars
        $vars = $O365Object.runspace_vars
        #Set Job params
        $Jobparam = @{
            ScriptBlock = $null;
            ImportCommands = $rsOptions.libCommands;
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
        #Get config
        try{
            $use_msGraph = [System.Convert]::ToBoolean($O365Object.internal_config.entraId.useMsGraph)
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            $use_msGraph = $false;
        }
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
			    Debug = $O365Object.Debug;
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
                    if($use_msGraph -and $O365Object.isConfidentialApp -eq $false ){
                        #Use Microsoft Graph
                        $tmp_user = Get-MonkeyGraphAADUser -UserId $member.ObjectId
                    }
                    elseif($use_msGraph -and $O365Object.isConfidentialApp -eq $True){
                        #Use Microsoft MSGraph
                        $tmp_user = Get-MonkeyMSGraphUser -UserPrincipalName $member.userPrincipalName
                    }
                    else{
                        #use Microsoft MSGraph
                        $tmp_user = Get-MonkeyMSGraphUser -UserPrincipalName $member.userPrincipalName
                    }
                    if($tmp_user){
                        [void]$all_members.Add($tmp_user)
                    }
                }
                elseif($member.principalType -ne "Group" -AND $member.principalType -ne "User"){
                    $raw_app = Get-MonkeyGraphAADObjectById -ObjectId $member.principalId
                    [void]$all_apps.Add($raw_app)
                }
                elseif($member.principalType -eq "Group"){
                    $msg = @{
                        MessageData = ($message.GroupWithRoleMessage -f $member.principalId, $role.properties.roleName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        InformationAction = $O365Object.InformationAction;
			            Debug = $O365Object.Debug;
                        Tags = @('AzureRbacGroupMember');
                    }
                    Write-Debug @msg
                    #Get group members
                    $group_members = Get-MonkeyGraphAADGroupMember -GroupId $member.principalId
                    if($group_members){
                        #Get real users
                        if($use_msGraph -and $O365Object.isConfidentialApp -eq $false){
                            $Jobparam.ScriptBlock = {Get-MonkeyGraphAADUser -UserId $_.ObjectId}
                        }
                        elseif($use_msGraph -and $O365Object.isConfidentialApp -eq $True){
                            #Get internal function
                            $Jobparam.ScriptBlock = {Get-MonkeyMSGraphUser -UserPrincipalName $_.userPrincipalName}
                        }
                        else{
                            #Get internal function
                            $Jobparam.ScriptBlock = {Get-MonkeyMSGraphUser -UserPrincipalName $_.userPrincipalName}
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

