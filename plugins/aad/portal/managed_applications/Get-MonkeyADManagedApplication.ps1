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


Function Get-MonkeyADManagedApplication{
    <#
        .SYNOPSIS
		Plugin to get managed applications from Azure AD

        .DESCRIPTION
		Plugin to get managed applications from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADManagedApplication
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
        $azure_ad_managed_applications = $app_by_principalIds = $null
        $AADConfig = $O365Object.internal_config.azuread
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.AzurePortal
        #create arrays
        $managed_apps = New-Object System.Collections.Generic.List[System.Object]
        $managed_apps_permissions = New-Object System.Collections.Generic.List[System.Object]
        $app_by_principalIds = New-Object System.Collections.Generic.List[System.Object]
        #Generate vars
        $vars = @{
            "O365Object"=$O365Object;
            "WriteLog"=$WriteLog;
            'Verbosity' = $Verbosity;
            'InformationAction' = $InformationAction;
        }
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure AD managed applications", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzurePortalManagedApplications');
        }
        Write-Information @msg
        try{
            #POST DATA
            $post_data = '{"accountEnabled":null,"isAppVisible":null,"appListQuery":0,"top":100,"loadLogo":false,"putCachedLogoUrlOnly":true,"nextLink":"","usedFirstPartyAppIds":null,"__ko_mapping__":{"ignore":[],"include":["_destroy"],"copy":[],"observe":[],"mappedProperties":{"accountEnabled":true,"isAppVisible":true,"appListQuery":true,"searchText":true,"top":true,"loadLogo":true,"putCachedLogoUrlOnly":true,"nextLink":true,"usedFirstPartyAppIds":true},"copiedProperties":{}}}'
            #Get managed applications
            $params = @{
                Authentication = $AADAuth;
                Query = "ManagedApplications/List";
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "POST";
                PostData = $post_data;
            }
            $azure_ad_managed_applications = Get-MonkeyAzurePortalObject @params
        }
        catch{
            Write-Error $_
            Write-Error "Unable to get managed applications from Azure AD"
        }
        if($null -ne $azure_ad_managed_applications){
            try{
                $param = @{
                    ScriptBlock = {Get-MonkeyADManagedAppProperty -managed_app $_};
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
                $managed_apps = $azure_ad_managed_applications | Invoke-MonkeyJob @param
            }
            catch{
                Write-Error $_
                Write-Error "Unable to get properties from managed applications from Azure AD"
            }
        }
        #Get Permissions for each application
        if($null -ne $managed_apps){
            foreach($managed_app in $managed_apps){
                if($null -ne ($managed_app.Psobject.Properties.Item('adminConsentedPerms')) -and $null -ne $managed_app.adminConsentedPerms){
                    foreach($permission in $managed_app.adminConsentedPerms){
                        #Create new permission object
                        $new_app_permission = $managed_app | Select-Object objectId, appId, displayName, appDisplayName
                        $new_app_permission | add-member NoteProperty -name resourceName -Value $permission.resourceName
                        $new_app_permission | add-member NoteProperty -name resourceAppId -Value $permission.resourceAppId
                        $new_app_permission | add-member NoteProperty -name permissionType -Value $permission.permissionType
                        $new_app_permission | add-member NoteProperty -name permissionDisplayName -Value $permission.permissionDisplayName
                        $new_app_permission | add-member NoteProperty -name permissionDescription -Value $permission.permissionDescription
                        $new_app_permission | add-member NoteProperty -name permissionId -Value $permission.permissionId
                        $new_app_permission | add-member NoteProperty -name consentType -Value $permission.consentType
                        $new_app_permission | add-member NoteProperty -name roleOrScopeClaim -Value $permission.roleOrScopeClaim
                        $new_app_permission | add-member NoteProperty -name principalIds -Value $permission.principalIds
                        #Add to array
                        [void]$managed_apps_permissions.Add($new_app_permission)
                    }
                }
                #Get user consented permissions
                if($null -ne ($managed_app.Psobject.Properties.Item('userConsentedPerms')) -and $null -ne $managed_app.userConsentedPerms){
                    foreach($permission in $managed_app.userConsentedPerms){
                        #Create new permission object
                        $new_app_permission = $managed_app | Select-Object objectId, appId, displayName, appDisplayName
                        $new_app_permission | add-member NoteProperty -name resourceName -Value $permission.resourceName
                        $new_app_permission | add-member NoteProperty -name resourceAppId -Value $permission.resourceAppId
                        $new_app_permission | add-member NoteProperty -name permissionType -Value $permission.permissionType
                        $new_app_permission | add-member NoteProperty -name permissionDisplayName -Value $permission.permissionDisplayName
                        $new_app_permission | add-member NoteProperty -name permissionDescription -Value $permission.permissionDescription
                        $new_app_permission | add-member NoteProperty -name permissionId -Value $permission.permissionId
                        $new_app_permission | add-member NoteProperty -name consentType -Value $permission.consentType
                        $new_app_permission | add-member NoteProperty -name roleOrScopeClaim -Value $permission.roleOrScopeClaim
                        $new_app_permission | add-member NoteProperty -name principalIds -Value $permission.principalIds
                        #Add to array
                        [void]$managed_apps_permissions.Add($new_app_permission)
                    }
                }
            }
        }
        if([System.Convert]::ToBoolean($AADConfig.GetManagedApplicationsByPrincipalId)){
            #Get managed applications permissions by principalIds
            $principalIds_managed_applications = $managed_apps_permissions | Where-Object {$_.consentType -eq "User"} -ErrorAction Ignore
            if($null -ne $principalIds_managed_applications){
                try{
                    $param = @{
                        ScriptBlock = {Get-MonkeyADManagedAppByPrincipalID -user_managed_app $_};
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
                    $app_by_principalIds = $principalIds_managed_applications | Invoke-MonkeyJob @param
                }
                catch{
                    Write-Error $_
                    Write-Error "Unable to get Principal Ids"
                }
            }
        }
        else{
            $app_by_principalIds = $null;
        }
    }
    End{
        #Return managed apps properties
        if ($managed_apps){
            $managed_apps.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.managed_applications.properties')
            [pscustomobject]$obj = @{
                Data = $managed_apps
            }
            $returnData.aad_managed_app = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD managed applications", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePortalManagedAppEmptyResponse');
            }
            Write-Warning @msg
        }
        #Return managed apps permissions properties
        if ($managed_apps_permissions){
            $managed_apps_permissions.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.managed_applications.permissions')
            [pscustomobject]$obj = @{
                Data = $managed_apps_permissions
            }
            $returnData.aad_managed_app_perms = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD managed app permissions", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePortalManagedAppEmptyResponse');
            }
            Write-Warning @msg
        }
        #Return managed apps permissions by principalId
        if ($app_by_principalIds){
            $app_by_principalIds.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.managed_applications.permissions.byprincipalId')
            [pscustomobject]$obj = @{
                Data = $app_by_principalIds
            }
            $returnData.aad_managed_app_perms_byusers = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD managed app user permissions", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzurePortalManagedAppEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
