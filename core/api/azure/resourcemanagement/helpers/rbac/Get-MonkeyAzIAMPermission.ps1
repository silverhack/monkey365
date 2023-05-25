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

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [String]$PrincipalId,

        [parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [Switch]$CurrentUser
    )
    Begin{
        #set null
        $objectId = $classic_administrators = $null
        if($CurrentUser -AND $O365Object.userPrincipalName){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $O365Object.userPrincipalName, "user");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRbacInfo');
            }
            Write-Information @msg
            #Get current Id
            $objectId = $O365Object.userId
        }
        elseif($CurrentUser -and $O365Object.isConfidentialApp){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $O365Object.clientApplicationId, "client application");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRbacInfo');
            }
            Write-Information @msg
            #Get current Id
            $objectId = $O365Object.clientApplicationId
        }
        elseif($PrincipalId){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $PrincipalId, "Principal Id");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRbacInfo');
            }
            Write-Information @msg
            #Get current Id
            $objectId = $PrincipalId
        }
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
            break
        }
    }
    Process{
        #Get Classic administrators
        $classic_administrators = Get-MonkeyAzClassicAdministrator
        if($null -ne $objectId){
            #Set new array
            $rbacPermissions = New-Object System.Collections.Generic.List[System.Object]
            $p = @{
		        ObjectId = $objectId;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $perms = Get-MonkeyAzObjectIAMPermission @p
            foreach($perm in @($perms)){
                [void]$rbacPermissions.Add($perm)
            }
        }
        else{
            #Set new array
            $rbacPermissions = New-Object System.Collections.Generic.List[System.Object]
            #create new param
            $new_param = @{}
            foreach($p in $PSBoundParameters.GetEnumerator()){
                if($p.Key -ne 'CurrentUser' -or $p.Key -ne 'PrincipalId'){
                    $new_param.Add($p.Key,$p.Value)
                }
            }
            #Get Role assignments
            $az_role_assignments = Get-MonkeyAzRoleAssignmentObject @new_param
            #Get Role definition
            $az_role_definition = Get-MonkeyAzRoleDefinitionObject @new_param
            #Iterate over all role assignments
            foreach($ra in @($az_role_assignments)){
                #Get role definition
                $rd = $az_role_definition | Where-Object {$_.id -eq $ra.Properties.roleDefinitionId}
                #Create PsObject
                $roleObject = [PsObject]@{
                    RoleTemplateId = $rd.name;
                    RoleId = $rd.id;
                    RoleName = $rd.properties.roleName;
                    RoleType = $rd.properties.type;
                    RoleDescription = $rd.properties.description;
                    RolePermissions = $rd.properties.permissions;
                    AssignedRoleScope = $rd.properties.assignableScopes;
                    createdOn = $rd.properties.createdOn;
                    updatedOn = $rd.properties.updatedOn;
                    createdBy = $rd.properties.createdBy;
                    updatedBy = $rd.properties.updatedBy;
                }
                #Get member
                $member = $ra.Properties
                if($member.PrincipalType -eq 'user'){
                    $msg = @{
		                MessageData = ($message.GenericWorkingMessage -f $member.principalId,"user Id");
			            callStack = (Get-PSCallStack | Select-Object -First 1);
			            logLevel = 'verbose';
			            InformationAction = $InformationAction;
                        Verbose = $O365Object.verbose;
			            Tags = @('AzureRbacInfo');
		            }
		            Write-Verbose @msg
                    #Get user's MFA detail
                    if($useAADOldAPIForUsers){
                        $p = @{
                            UserId = $member.principalId;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $userObject = Get-MonkeyGraphAADUser @p
                    }
                    else{
                        $p = @{
                            UserId = $member.principalId;
                            APIVersion = $aadConf.api_version;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $userObject = Get-MonkeyMsGraphMFAUserDetail @p
                    }
                    #Set new array
                    $rbacArray = New-Object System.Collections.Generic.List[System.Object]
                    [void]$rbacArray.Add($roleObject)
                    #Add to object
                    $userObject | Add-Member -type NoteProperty -name roleAssignmentInfo -value $rbacArray -Force
                    if($userObject){
                        [void]$rbacPermissions.Add($userObject)
                    }
                }
                elseif($member.principalType -eq 'Group'){
                    $msg = @{
		                MessageData = ($message.GenericWorkingMessage -f $member.principalId,"group Id");
			            callStack = (Get-PSCallStack | Select-Object -First 1);
			            logLevel = 'verbose';
			            InformationAction = $InformationAction;
                        Verbose = $O365Object.verbose;
			            Tags = @('AzureRbacInfo');
		            }
		            Write-Verbose @msg
                    #Get members
                    $p = @{
                        GroupId = $member.principalId;
                        Parents = @(('{0}' -f $member.principalId));
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $members = Get-MonkeyMSGraphGroupTransitiveMember @p
                    #Get user's MFA detail
                    if($useAADOldAPIForUsers){
                        foreach($member in @($members)){
                            $p = @{
                                UserId = $member.Id;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $userObject = Get-MonkeyGraphAADUser @p
                            #Set new array
                            $rbacArray = New-Object System.Collections.Generic.List[System.Object]
                            [void]$rbacArray.Add($roleObject)
                            #Add to object
                            $userObject | Add-Member -type NoteProperty -name roleAssignmentInfo -value $rbacArray -Force
                            if($userObject){
                                [void]$rbacPermissions.Add($userObject)
                            }
                        }
                    }
                    else{
                        foreach($member in @($members)){
                            $p = @{
                                UserId = $member.principalId;
                                APIVersion = $aadConf.api_version;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $userObject = Get-MonkeyMsGraphMFAUserDetail @p
                            #Set new array
                            $rbacArray = New-Object System.Collections.Generic.List[System.Object]
                            [void]$rbacArray.Add($roleObject)
                            #Add to object
                            $userObject | Add-Member -type NoteProperty -name roleAssignmentInfo -value $rbacArray -Force
                            if($userObject){
                                [void]$rbacPermissions.Add($userObject)
                            }
                        }
                    }
                }
                elseif($member.principalType -eq 'ServicePrincipal'){
                    $msg = @{
		                MessageData = ($message.GenericWorkingMessage -f $member.principalId,"Service Principal Id");
			            callStack = (Get-PSCallStack | Select-Object -First 1);
			            logLevel = 'verbose';
			            InformationAction = $InformationAction;
                        Verbose = $O365Object.verbose;
			            Tags = @('AzureRbacInfo');
		            }
		            Write-Verbose @msg
                    #Get Service Principal
                    $p = @{
                        ServicePrincipalId = $member.principalId;
                        APIVersion = $aadConf.api_version;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $spObject = Get-MonkeyMSGraphAADServicePrincipal @p
                    #Set new array
                    $rbacArray = New-Object System.Collections.Generic.List[System.Object]
                    [void]$rbacArray.Add($roleObject)
                    #Add to object
                    $spObject | Add-Member -type NoteProperty -name roleAssignmentInfo -value $rbacArray -Force
                    if($spObject){
                        [void]$rbacPermissions.Add($spObject)
                    }
                }
                else{
                    $msg = @{
                        MessageData = ($message.RbacUnknownPrincipalType -f $member.principalType);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureRbacInfo');
                    }
                    Write-Verbose @msg
                }
            }
        }
    }
    End{
        #Check for classic administrators
        if($null -ne $classic_administrators){
            foreach($iam in $rbacPermissions){
                $roles = $classic_administrators | Where-Object {if($iam.psobject.properties.item('userPrincipalName')){$_.emailAddress -eq $iam.userPrincipalName}}
                foreach($role in @($roles)){
                    $roleObject = [PsObject]@{
                        RoleTemplateId = $null;
                        RoleId = $role.rawObject.id;
                        RoleName = $role.Role;
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
                    [void]$iam.roleAssignmentInfo.Add($roleObject)
                }
            }
        }
        #return permissions
        return $rbacPermissions
    }
}