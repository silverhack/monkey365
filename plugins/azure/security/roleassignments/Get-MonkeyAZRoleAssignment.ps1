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


Function Get-MonkeyAZRoleAssignment{
    <#
        .SYNOPSIS
		Plugin to get Role assignments from Azure

        .DESCRIPTION
		Plugin to get Role assignments from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZRoleAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        $aad_auth = $O365Object.auth_tokens.Graph
        #Get Config
        $AADConfig = $O365Object.internal_config.azuread
        $AzureAuthConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureAuthorization"} | Select-Object -ExpandProperty resource
        #Get Auth Type
        $auth_type = $O365Object.AuthType
        #Get primary object
        $all_classic_admins = @()
        $all_rbac_users = @()
        $all_groups = @()
        #Get Config
        $use_azure_portal = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.useAzurePortalAPI)
        $dump_users_with_graph_api = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.dumpAdUsersWithInternalGraphAPI)
        $all_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        #Set Job params
        $vars = @{
            "O365Object"=$O365Object;
            "WriteLog"=$WriteLog;
            'Verbosity' = $Verbosity;
            'InformationAction' = $InformationAction;
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
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Role Based Access Control", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureRBACInfo');
        }
        Write-Information @msg
        #List Classic Administrators
        $params = @{
            Authentication = $rm_auth;
            Provider = $AzureAuthConfig.provider;
            ObjectType = "classicAdministrators";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $AzureAuthConfig.api_version;
        }
        $classic_administrators = Get-MonkeyRMObject @params
        foreach($admin in $classic_administrators){
            $role = $admin.properties.role.split(";")
            foreach ($r in $role){
                #Create custom object
                $classic_admin_obj = [hashtable]@{
                    emailaddress = $admin.properties.emailAddress
                    role = $r
                    rawObject =$admin
                }
                $classic_admin_obj = New-Object psobject -prop $classic_admin_obj
                #Decorate object and add to list
                $classic_admin_obj.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ClassicAdministrators')
                $all_classic_admins+= $classic_admin_obj
            }
        }
        #Get RoleAssignments
        $params = @{
            Authentication = $rm_auth;
            Provider = $AzureAuthConfig.provider;
            ObjectType = "roleAssignments";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = "2015-07-01";
        }
        $role_assignments = Get-MonkeyRMObject @params
        $roleIds = $role_assignments.properties | Select-Object -ExpandProperty principalId
        $Body = @{
            "objectIds" = $roleIds;
            "includeDirectoryObjectReferences" = "true"
        }
        $JsonData = $Body | ConvertTo-Json
        #POST Request
        #check if internal version is needed
        if([System.Convert]::ToBoolean($O365Object.internal_config.azuread.dumpAdUsersWithInternalGraphAPI) -and $auth_type -notlike "C*"){
            $AADConfig.api_version = $O365Object.internal_config.azuread.internal_api_version
            $msg = @{
                MessageData = ($message.GraphAPISwitchMessage);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphUsersAPISwitch');
            }
            Write-Information @msg
        }
        else{
            $AADConfig.api_version =  $AADConfig.api_version
        }
        $params = @{
            Authentication = $aad_auth;
            ObjectType = "getObjectsByObjectIds";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "POST";
            APIVersion = $AADConfig.api_version;
            Data = $JsonData;
        }
        $all_role_assignments = Get-MonkeyGraphObject @params
        #Get RoleAssignments at the specified scope and any of its child scopes
        #https://docs.microsoft.com/en-us/azure/active-directory/role-based-access-control-manage-access-rest
        $URI = ('{0}subscriptions/{1}/providers/Microsoft.Authorization/roleDefinitions?$filter=atScopeAndBelow()&api-version=2015-07-01' -f $O365Object.Environment.ResourceManager, $rm_auth.subscriptionId)
        $params = @{
            Authentication = $rm_auth;
            OwnQuery = $URI;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
        }
        $Scoped_RoleAssignments = Get-MonkeyRMObject @params
        <#
        #Get Custom role definitions
        $objectType = ("roleDefinitions?{0}" -f [System.Web.HttpUtility]::UrlEncode("`$filter=type eq 'CustomRole'"))
        $params = @{
            Authentication = $rm_auth;
            Provider = $AzureAuthConfig.provider;
            ObjectType = $objectType;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = "2018-01-01-preview";
        }
        $custom_roles = Get-MonkeyRMObject @params
        if($null -ne $custom_roles){
            #Add custom roles to array
            $Scoped_RoleAssignments += $custom_roles
        }
        #>
        foreach ($obj in $all_role_assignments){
            $match = $role_assignments.properties | Where-Object {$_.principalId -eq $obj.objectId}
            if (($match -AND $obj.objectType -eq "User")){
                #Try to get the RoleDefinitionName
                $RoleID = $match.roleDefinitionId.split('/')[6]
                $RoleProperties = $Scoped_RoleAssignments | Where-Object {$_.name -eq $RoleID}
                #Get Detailed User
                $tmp_user = $null
                if($dump_users_with_graph_api){
                    #Get user
                    $tmp_user = Get-AADDetailedUser -user $obj
                }
                elseif($use_azure_portal -and $auth_type -notlike "C*"){
                    #Get internal function
                    $tmp_user = Get-MonkeyADPortalDetailedUser -user $obj
                }
                else{
                    #Get internal function
                    $tmp_user = Get-AADDetailedUser -user $obj
                }
                #Check if data
                if($null -ne $tmp_user){
                    #Add members to Object
                    $tmp_user | Add-Member -type NoteProperty -name scope -value $match.scope
                    $tmp_user | Add-Member -type NoteProperty -name roleName -value $RoleProperties.properties.roleName
                    $tmp_user | Add-Member -type NoteProperty -name roleDescription -value $RoleProperties.properties.description
                    $tmp_user | Add-Member -type NoteProperty -name createdOn -value $match.createdOn
                    $tmp_user | Add-Member -type NoteProperty -name updatedOn -value $match.updatedOn
                    $tmp_user | Add-Member -type NoteProperty -name createdBy -value $match.createdBy
                    $tmp_user | Add-Member -type NoteProperty -name updatedBy -value $match.updatedBy
                    #Add to Object
                    $all_rbac_users+=$tmp_user
                    [void]$all_users.Add($tmp_user)
                }
            }
            elseif(($match -AND $obj.objectType -eq "Group")){
                #Try to get the RoleDefinitionName
                $RoleID = $match.roleDefinitionId.split('/')[6]
                $RoleProperties = $Scoped_RoleAssignments | Where-Object {$_.name -eq $RoleID}
                $msg = @{
                    MessageData = ($message.GroupWithRoleMessage -f $obj.displayName, $RoleProperties.properties.roleName);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    InformationAction = $InformationAction;
                    Tags = @('AzureGraphGroupInfo');
                }
                Write-Information @msg
                #Add group to array
                $all_groups +=$obj.objectId
                $p = @{
                    Group = $obj
                    all_groups = $all_groups;
                }
                $Members+= Get-MonkeyAZGroupMember @p
                if($Members){
                    $Members | ForEach-Object {$_ | Add-Member -type NoteProperty -name properties -value $RoleProperties.properties -Force}
                    #Get real users
                    if($dump_users_with_graph_api){
                        $Jobparam.ScriptBlock = {Get-AADDetailedUser -user $_}
                    }
                    elseif(-NOT $dump_users_with_graph_api -AND $use_azure_portal -and $auth_type -notlike "C*"){
                        #Get internal function
                        $Jobparam.ScriptBlock = {Get-MonkeyADPortalDetailedUser -user $_}
                    }
                    else{
                        #Get internal function
                        $Jobparam.ScriptBlock = {Get-AADDetailedUser -user $_}
                    }
                    if($null -ne $Jobparam.ScriptBlock){
                        #Get Users
                        $Members | Invoke-MonkeyJob @Jobparam | ForEach-Object {
                            if($_){
                                $_ | Add-Member -type NoteProperty -name scope -value $match.scope
                                $_ | Add-Member -type NoteProperty -name roleName -value $RoleProperties.properties.roleName
                                $_ | Add-Member -type NoteProperty -name roleDescription -value $RoleProperties.properties.description
                                $_ | Add-Member -type NoteProperty -name createdOn -value $match.createdOn
                                $_ | Add-Member -type NoteProperty -name updatedOn -value $match.updatedOn
                                $_ | Add-Member -type NoteProperty -name createdBy -value $match.createdBy
                                $_ | Add-Member -type NoteProperty -name updatedBy -value $match.updatedBy
                                [void]$all_users.Add($_)
                                $all_rbac_users+=$_
                            }
                        }
                    }
                }
            }
            elseif(($match -AND $obj.objectType -ne "Group" -AND $obj.objectType -ne "User")){
                $RoleID = $match.roleDefinitionId.split('/')[6]
                $RoleProperties = $Scoped_RoleAssignments | Where-Object {$_.name -eq $RoleID}
                #Add members to Object
                $obj | Add-Member -type NoteProperty -name scope -value $match.scope
                $obj | Add-Member -type NoteProperty -name roleName -value $RoleProperties.properties.roleName
                $obj | Add-Member -type NoteProperty -name roleDescription -value $RoleProperties.properties.description
                $obj | Add-Member -type NoteProperty -name createdOn -value $match.createdOn
                $obj | Add-Member -type NoteProperty -name updatedOn -value $match.updatedOn
                $obj | Add-Member -type NoteProperty -name createdBy -value $match.createdBy
                $obj | Add-Member -type NoteProperty -name updatedBy -value $match.updatedBy
                #Add to Object
                $all_rbac_users+=$obj
            }
        }
        #Normalize users
    }
    End{
        if ($all_rbac_users){
            $all_rbac_users.PSObject.TypeNames.Insert(0,'Monkey365.Azure.RBACUsers')
            [pscustomobject]$obj = @{
                Data = $all_rbac_users
            }
            $returnData.az_rbac_users = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Role Access Based Control", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureRBACEmptyResponse');
            }
            Write-Warning @msg
        }
        if ($all_classic_admins){
            $all_classic_admins.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ClassicAdmins')
            [pscustomobject]$obj = @{
                Data = $all_classic_admins
            }
            $returnData.az_classic_admins = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Classic Admins", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureClassicAdminsEmptyResponse');
            }
            Write-Warning @msg
        }
        if ($Scoped_RoleAssignments){
            $Scoped_RoleAssignments.PSObject.TypeNames.Insert(0,'Monkey365.Azure.RoleDefinitions')
            [pscustomobject]$obj = @{
                Data = $Scoped_RoleAssignments
            }
            $returnData.az_role_definitions = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Role Definitions", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureRoleDefinitionsEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
