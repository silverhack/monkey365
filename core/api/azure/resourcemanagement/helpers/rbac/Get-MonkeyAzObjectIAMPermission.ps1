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

Function Get-MonkeyAzObjectIAMPermission{
    <#
        .SYNOPSIS

        Get Azure IAM permission for user or servicePrincipal object

        .DESCRIPTION

        Get Azure IAM permission for user or servicePrincipal object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzObjectIAMPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [String]$ObjectId
    )
    Begin{
        #Set array
        $iam_permissions = New-Object System.Collections.Generic.List[System.Object]
        #Get Classic administrators
        $classic_administrators = Get-MonkeyAzClassicAdministrator
    }
    Process{
        #create new param
        $new_param = @{}
        foreach($p in $PSBoundParameters.GetEnumerator()){
            if($p.Key -ne 'ObjectId'){
                $new_param.Add($p.Key,$p.Value)
            }
        }
        #Add ObjectId to param
        $new_param.Add('AssignedTo',$ObjectId)
        $new_param.Add('AtScope',$false)
        #Get Role assignments
        $az_role_assignments = Get-MonkeyAzRoleAssignmentObject @new_param
        #set var
        $identity = $rawIdentity = $null
        if($null -ne $az_role_assignments){
            #Get all role definition objects
            $role_defs = $az_role_assignments.properties | Select-Object -ExpandProperty roleDefinitionId -ErrorAction Ignore
            #Get identity
            $identity = $az_role_assignments.properties | Select-Object principalId,principalType -Unique -ErrorAction Ignore
            if($null -ne $identity -and $identity.principalType -eq 'User'){
                #Get user's MFA detail
                #check command
                if($null -ne (Get-Command -Name "Get-MonkeyGraphAADUser" -ErrorAction Ignore)){
                    $p = @{
                        UserId = $identity.principalId;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $rawIdentity = Get-MonkeyGraphAADUser @p
                }
                elseif($null -ne (Get-Command -Name "Get-MonkeyMsGraphMFAUserDetail" -ErrorAction Ignore)){
                    $p = @{
                        UserId = $identity.principalId;
                        APIVersion = $O365Object.internal_config.azuread.provider.msgraph.api_version;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $rawIdentity = Get-MonkeyMsGraphMFAUserDetail @p
                }
                else{
                    $msg = @{
                        MessageData = "Azure AD users command not loaded";
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        Verbose = $O365Object.verbose;
                        Tags = @('AzureRbacUserError');
                    }
                    Write-Verbose @msg
                }
            }
            elseif($null -ne $identity -and $identity.principalType -eq 'ServicePrincipal'){
                #Get Service Principal
                $p = @{
                    ServicePrincipalId = $identity.principalId;
                    APIVersion = $O365Object.internal_config.azuread.provider.msgraph.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $rawIdentity = Get-MonkeyMSGraphAADServicePrincipal @p
            }
            elseif($null -ne $identity -and $identity.principalType -eq 'Group'){
                #Get group members
                $p = @{
                    GroupId = $identity.principalId;
                    Parents = @($identity.principalId);
                    APIVersion = $O365Object.internal_config.azuread.provider.msgraph.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $all_members = Get-MonkeyMSGraphGroupTransitiveMember @p
                if($null -ne $all_members){
                    #Get objectId
                    $rawIdentity = $all_members | Where-Object {$_.id -eq $ObjectId}
                }
            }
            else{
                $msg = @{
                    MessageData = ($message.RbacUnknownPrincipalType -f $identity.principalType);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Verbose = $O365Object.verbose;
                    Tags = @('AzureRbacInfo');
                }
                Write-Verbose @msg
            }
            #Get Role definition objects
            foreach($rd in @($role_defs)){
                $p = @{
                    Id = $rd;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $role_definition = Get-MonkeyAzRoleDefinitionObject @p
                if($role_definition){
                    $roleObject = [PsObject]@{
                        RoleTemplateId = $role_definition.name;
                        RoleId = $role_definition.id;
                        RoleName = $role_definition.properties.roleName;
                        RoleType = $role_definition.properties.type;
                        RoleDescription = $role_definition.properties.description;
                        RolePermissions = $role_definition.properties.permissions;
                        AssignedRoleScope = $role_definition.properties.assignableScopes;
                        createdOn = $role_definition.properties.createdOn;
                        updatedOn = $role_definition.properties.updatedOn;
                        createdBy = $role_definition.properties.createdBy;
                        updatedBy = $role_definition.properties.updatedBy;
                    }
                    #Add to array
                    [void]$iam_permissions.Add($roleObject)
                }
            }
            #Check if classic permission
            if($classic_administrators -and $null -ne $rawIdentity){
                $roles = $classic_administrators | Where-Object {if($rawIdentity.psobject.properties.item('userPrincipalName')){$_.emailAddress -eq $rawIdentity.userPrincipalName}} | Select-Object -ExpandProperty role
                foreach($role in @($roles)){
                    $roleObject = [PsObject]@{
                        RoleTemplateId = $null;
                        RoleId = $null;
                        RoleName = $role;
                        RoleType = 'classicAdministrator';
                        RoleDescription = $null;
                        RolePermissions = $null;
                        AssignedRoleScope = $null;
                        createdOn = $null;
                        updatedOn = $null;
                        createdBy = $null;
                        updatedBy = $null;
                    }
                    #Add to array
                    [void]$iam_permissions.Add($roleObject)
                }
            }
        }
    }
    End{
        #Add IAM info to identity
        if($null -ne $rawIdentity){
            $rawIdentity | Add-Member -type NoteProperty -name roleAssignmentInfo -value $iam_permissions -Force
            return $rawIdentity
        }
    }
}