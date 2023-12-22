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


Function Get-MonkeyMSGraphAADDirectoryRole{
    <#
        .SYNOPSIS
		Get Azure AD directory role information

        .DESCRIPTION
		Get Azure AD directory role information

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAADDirectoryRole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'Role', HelpMessage="Role only")]
        [Switch]$RoleOnly,

        [Parameter(Mandatory=$True, ParameterSetName = 'User', HelpMessage="User id")]
        [String]$UserId,

        [parameter(Mandatory=$True, ParameterSetName = 'CurrentUser', HelpMessage="Current user")]
        [Switch]$CurrentUser,

        [Parameter(Mandatory=$True, ParameterSetName = 'PrincipalId', HelpMessage="Principal Id")]
        [String]$PrincipalId,

        [Parameter(Mandatory=$True, ParameterSetName = 'Group', HelpMessage="Group Id")]
        [String]$GroupId,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        #Get Config
        try{
            $aadConf = $O365Object.internal_config.entraId.provider.msgraph
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
            throw ("[ConfigError] {0}: {1}" -f $message.MonkeyInternalConfigError,$_.Exception.Message)
        }
        #Get param for nested jobs
        if($O365Object.useOldAADAPIForUsers){
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
        else{
            $new_arg = @{
                APIVersion = $aadConf.api_version;
            }
            $jobParam = @{
	            ScriptBlock = { Get-MonkeyMsGraphMFAUserDetail -User $_ };
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
    Process{
        if($PSCmdlet.ParameterSetName -eq 'Role'){
            $p = @{
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphAADRoleAssignment @p
        }
        Elseif($PSCmdlet.ParameterSetName -eq 'UserId'){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $UserId, "user");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRbacInfo');
            }
            Write-Information @msg
            $p = @{
                UserId = $UserId;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphUserDirectoryRole @p
        }
        Elseif($PSCmdlet.ParameterSetName -eq 'CurrentUser'){
            if($O365Object.userId){
                $msg = @{
                    MessageData = ($message.RbacPermissionsMessage -f $O365Object.userPrincipalName, "user");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureRbacInfo');
                }
                Write-Information @msg
                $p = @{
                    UserId = $O365Object.userId;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                Get-MonkeyMSGraphUserDirectoryRole @p
            }
            elseif($O365Object.isConfidentialApp){
                $msg = @{
                    MessageData = ($message.RbacPermissionsMessage -f $O365Object.clientApplicationId, "client application");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureRbacInfo');
                }
                Write-Information @msg
                $p = @{
                    PrincipalId = $O365Object.clientApplicationId;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                Get-MonkeyMSGraphServicePrincipalDirectoryRole @p
            }
        }
        Elseif($PSCmdlet.ParameterSetName -eq 'PrincipalId'){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $PrincipalId, "Service principal");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRbacInfo');
            }
            Write-Information @msg
            $p = @{
                PrincipalId = $PrincipalId;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphServicePrincipalDirectoryRole @p
        }
        Elseif($PSCmdlet.ParameterSetName -eq 'GroupId'){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $GroupId, "Group");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRbacInfo');
            }
            Write-Information @msg
            $p = @{
                GroupId = $GroupId;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphGroupDirectoryRoleMemberOf @p
        }
        Else{#All rbac permissions
            try{
                $allRBAC = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                #Get all RBAC info
                $p = @{
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $role_assignments = Get-MonkeyMSGraphAADRoleAssignment @p | Group-Object roleDefinitionId
                if($role_assignments){
                    foreach ($ra in $role_assignments){
                        $allmembers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                        #Get role assignment
                        $ra_info = $ra.Group.roleDefinition | Select-Object -Unique
                        #get Members
                        $members = $ra.Group.Principal
                        #Get groups
                        $grp = @($ra.Group.Principal).Where({$_.'@odata.type' -eq '#microsoft.graph.group'})
                        #Get users
                        $usr = @($ra.Group.Principal).Where({$_.'@odata.type' -eq '#microsoft.graph.user'})
                        #Check if check for MFA
                        if($O365Object.canRequestMFAForUsers){
                            if($O365Object.useOldAADAPIForUsers){
                                $usr = $usr | Select-Object -ExpandProperty Id
                                $member = $usr | Invoke-MonkeyJob @jobParam
                            }
                            else{
                                $member = $usr | Invoke-MonkeyJob @jobParam
                            }
                            if($member){
                                foreach($m in @($member)){
                                    [void]$allmembers.Add($m)
                                }
                            }
                        }
                        else{
                            #Add members
                            $allmembers.AddRange($usr)
                        }
                        #Get service Principals
                        $sp = @($ra.Group.Principal).Where({$_.'@odata.type' -eq '#microsoft.graph.servicePrincipal'})
                        #Add members
                        $allmembers.AddRange($sp)
                        #get Effective members
                        if($grp.Count -gt 0){
                            foreach($group in $grp){
                                #Get members
                                $p = @{
                                    GroupId = $group.id;
                                    Parents = @(('{0}' -f $group.id));
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                }
                                $members = Get-MonkeyMSGraphGroupTransitiveMember @p
                                if($members){
                                    #Check if check for MFA
                                    if($O365Object.canRequestMFAForUsers){
                                        if($O365Object.useOldAADAPIForUsers){
                                            $members = $members | Select-Object -ExpandProperty Id
                                            $all_members = $usr | Invoke-MonkeyJob @jobParam
                                        }
                                        else{
                                            $all_members = $members | Invoke-MonkeyJob @jobParam
                                        }
                                        if($all_members){
                                            foreach($m in $all_members){
                                                [void]$allmembers.Add($m)
                                            }
                                        }
                                    }
                                    else{
                                        foreach($member in $members){
                                            [void]$allmembers.Add($member)
                                        }
                                    }
                                }
                            }
                        }
                        #Populate Object
                        $ra_info | Add-Member -type NoteProperty -name users -value $usr -Force
                        $ra_info | Add-Member -type NoteProperty -name groups -value $grp -Force
                        $ra_info | Add-Member -type NoteProperty -name servicePrincipal -value $sp -Force
                        $ra_info | Add-Member -type NoteProperty -name effectiveMembers -value $allmembers -Force
                        $allRBAC.Add($ra_info);
                    }
                }
                Write-Output $allRBAC -NoEnumerate
            }
            catch{
                $msg = @{
                    MessageData = ($_.Exception.Message);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose
                    Tags = @('MonkeyMSGraphAADRBACError');
                }
                Write-Verbose @msg
            }
        }
    }
    End{
        #Nothing to do here
    }
}