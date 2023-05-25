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
        [Parameter(Mandatory=$True, ParameterSetName = 'RoleOnly', ValueFromPipeline = $True)]
        [Switch]$RoleOnly,

        [Parameter(Mandatory=$True, ParameterSetName = 'UserId', ValueFromPipeline = $True)]
        [String]$UserId,

        [parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [Switch]$CurrentUser,

        [Parameter(Mandatory=$True, ParameterSetName = 'PrincipalId', ValueFromPipeline = $True)]
        [String]$PrincipalId,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        #Get Config
        try{
            $aadConf = $O365Object.internal_config.azuread.provider.msgraph
            $useAADOldAPIForUsers = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.provider.graph.getUsersWithAADInternalAPI)
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
            $useAADOldAPIForUsers = $false;
            break
        }
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'UserId'){
            $p = @{
                UserId = $objectId;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphUserDirectoryRole @p
        }
        elseif($CurrentUser.IsPresent){
            #Get current Id
            if($null -ne $O365Object.userId){
                $objectId = $O365Object.userId
                $p = @{
                    UserId = $objectId;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                Get-MonkeyMSGraphUserDirectoryRole @p
            }
            elseif($O365Object.isConfidentialApp){
                #Get current Id
                $objectId = $O365Object.clientApplicationId
                $p = @{
                    PrincipalId = $objectId;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                Get-MonkeyMSGraphServicePrincipalDirectoryRole @p
            }
        }
        elseif($PSCmdlet.ParameterSetName -eq 'PrincipalId'){
            $p = @{
                PrincipalId = $PrincipalId;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphServicePrincipalDirectoryRole @p
        }
        elseif($PSCmdlet.ParameterSetName -eq 'RoleOnly'){
            $p = @{
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphAADRoleAssignment @p
        }
        elseif($PSCmdlet.ParameterSetName -eq 'All'){
            $p = @{
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $role_assignments = Get-MonkeyMSGraphAADRoleAssignment @p
            #Set array
            $all_members = New-Object System.Collections.Generic.List[System.Object]
            foreach ($role in $role_assignments){
                if($role.principal.'@odata.type' -eq '#microsoft.graph.group'){
                    $msg = @{
			            MessageData = ($message.GenericWorkingMessage -f $role.principal.displayName,"group object");
			            callStack = (Get-PSCallStack | Select-Object -First 1);
			            logLevel = 'verbose';
			            InformationAction = $InformationAction;
                        Verbose = $O365Object.verbose;
			            Tags = @('AzureGraphDirectoryRole');
		            }
		            Write-Verbose @msg
                    #Get members
                    $p = @{
                        GroupId = $role.principal.id;
                        Parents = @(('{0}' -f $role.principal.id));
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $members = Get-MonkeyMSGraphGroupTransitiveMember @p
                    if($members){
                        foreach($member in @($members)){
                            #Populate object
                            $roleObject = [PsObject]@{
                                AssignedRole = $role.roleDefinition.displayName;
                                AssignedRoleDescription = $role.roleDefinition.description;
                                AssignedRoleScope = $role.directoryScopeId;
                                IsBuiltIn = $role.roleDefinition.isBuiltIn;
                                RoleTemplateId = $role.roleDefinition.templateId;
                            }
                            #Get user's MFA details
                            if($useAADOldAPIForUsers){
                                $params = @{
                                    UserId = $member.id;
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                }
                                $member = Get-MonkeyGraphAADUser @params
                            }
                            else{
                                $params = @{
                                    User = $member;
                                    APIVersion = $aadConf.api_version;
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                }
                                $member = Get-MonkeyMsGraphMFAUserDetail @params
                            }
                            #Add to object
                            $member | Add-Member -type NoteProperty -name directoryRoleInfo -value $roleObject -Force
                            #Add to array
                            [void]$all_members.Add($member)
                        }
                    }
                }
                elseif($role.principal.'@odata.type' -eq '#microsoft.graph.user'){
                    #Populate object
                    $roleObject = [PsObject]@{
                        AssignedRole = $role.roleDefinition.displayName;
                        AssignedRoleDescription = $role.roleDefinition.description;
                        AssignedRoleScope = $role.directoryScopeId;
                        IsBuiltIn = $role.roleDefinition.isBuiltIn;
                        RoleTemplateId = $role.roleDefinition.templateId;
                    }
                    #Get userObject
                    $userObject = $role.Principal
                    #Get user's MFA detail
                    if($useAADOldAPIForUsers){
                        $params = @{
                            UserId = $userObject.id;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $userObject = Get-MonkeyGraphAADUser @params
                    }
                    else{
                        $params = @{
                            User = $member;
                            APIVersion = $aadConf.api_version;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $userObject = Get-MonkeyMsGraphMFAUserDetail @params
                    }
                    if($userObject){
                        #Add to object
                        $userObject | Add-Member -type NoteProperty -name directoryRoleInfo -value $roleObject -Force
                        #Add to array
                        [void]$all_members.Add($userObject)
                    }
                }
                else{#Service Principal
                    #Populate object
                    $roleObject = [PsObject]@{
                        AssignedRole = $role.roleDefinition.displayName;
                        AssignedRoleDescription = $role.roleDefinition.description;
                        AssignedRoleScope = $role.directoryScopeId;
                        IsBuiltIn = $role.roleDefinition.isBuiltIn;
                        RoleTemplateId = $role.roleDefinition.templateId;
                    }
                    #Get Service Principal
                    $sp = $role.Principal
                    #Add to object
                    $sp | Add-Member -type NoteProperty -name directoryRoleInfo -value $roleObject -Force
                    #Add to array
                    [void]$all_members.Add($sp)
                }
            }
            #return all_members
            $all_members
        }
    }
}