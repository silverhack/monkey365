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

Function Get-MonkeyMSGraphAADAPPPermission {
<#
        .SYNOPSIS
		Plugin to get application permissions from Azure AD

        .DESCRIPTION
		Plugin to get application permissions from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAADAPPPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True)]
        [Object]$Application,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        if($APIVersion -eq 'beta'){
            $consentPath = 'publishedPermissionScopes'
        }
        else{
            $consentPath = 'oauth2PermissionScopes'
        }
    }
    Process{
        try{
            $msg = @{
			    MessageData = ($message.EntraIDAppPermissionInfo -f $Application.appId);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDApplicationInfo');
		    }
		    Write-Information @msg
            $appRoleAssignment = $Oauth2Grants = $org_consent = $servicePrincipal = $all_permissions = $null
            $all_permissions = New-Object System.Collections.Generic.List[System.Object]
            #Search for associated service principal
            $appId = $Application.appId
            #Get Service Principal
            $params = @{
                Filter = ("appId eq '{0}'" -f $appId);
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $servicePrincipal = Get-MonkeyMSGraphAADServicePrincipal @params
            if($null -ne $servicePrincipal){
                #Get Servcice Principal role assignment
                $params = @{
                    ServicePrincipalId = $servicePrincipal.id;
                    ElementType = "appRoleAssignments";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $appRoleAssignment = Get-MonkeyMSGraphAADServicePrincipal @params
                #Get OauthGrants
                $params = @{
                    Filter = ("clientId eq '{0}' and consentType eq 'AllPrincipals'" -f $servicePrincipal.id);
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $Oauth2Grants = Get-MonkeyMSGraphOauth2PermissionGrant @params
                Start-Sleep -Milliseconds 200
            }
            #Enumerate permissions
            if($null -ne $Application.PsObject.Properties.Item('requiredResourceAccess')){
                foreach($access in $Application.requiredResourceAccess){
                    $appId = $access.resourceAppId
                    $resourceAccess = $access.resourceAccess
                    #Get Service Principal
                    $params = @{
                        Filter = ("appId eq '{0}'" -f $appId);
                        APIVersion = $APIVersion;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $Allowed_ServicePrincipal = Get-MonkeyMSGraphAADServicePrincipal @params
                    #Get permissions
                    if($Allowed_ServicePrincipal){
                        foreach($rsrc_access in $resourceAccess){
                            #Create new PsObject
                            $new_permission = New-MonkeyAADAppPermissionObject -Application $Application
                            #Add Service Principal Name
                            $new_permission.ResourceObjectId = $Allowed_ServicePrincipal.id;
                            $new_permission.ResourceDisplayName = $Allowed_ServicePrincipal.appDisplayName;
                            $new_permission.ResourceAppId = $Allowed_ServicePrincipal.appId;
                            $permission = $Allowed_ServicePrincipal.appRoles | Where-Object {$_.id -eq $rsrc_access.Id}
                            if($null -eq $permission){
                                $new_permission.PermissionType = "Delegated";
                                #Get consent permission
                                $consent_perm = $Allowed_ServicePrincipal.($consentPath) | Where-Object {$_.id -eq $rsrc_access.Id}
                                if($null -ne $consent_perm){
                                    #Add permission Id
                                    $new_permission.PermissionId = $consent_perm.id;
                                    if($null -ne $Oauth2Grants){
                                        $org_consent_perm = $Oauth2Grants | Where-Object {$_.scope -eq $consent_perm.value}
                                        if($org_consent_perm){
                                            $new_permission.GrantType = ("Granted for {0}" -f $O365Object.Tenant.TenantName);
                                        }
                                        else{
                                            $new_permission.GrantType = ("Not granted for {0}" -f $O365Object.Tenant.TenantName);
                                        }
                                    }
                                }
                            }
                            else{
                                $new_permission.PermissionType = "Application";
                                $new_permission.PermissionId = $permission.id;
                                if($null -ne $appRoleAssignment){
                                    $org_consent = $appRoleAssignment | Where-Object {$_.appRoleId -eq $permission.Id}
                                }
                                if($org_consent){
                                    $new_permission.GrantType = ("Granted for {0}" -f $O365Object.Tenant.TenantName);
                                }
                                else{
                                    $new_permission.GrantType = ("Not granted for {0}" -f $O365Object.Tenant.TenantName);
                                }
                            }
                            #Get description
                            $published_permission = $Allowed_ServicePrincipal.($consentPath) | Where-Object {$_.id -eq $rsrc_access.id}
                            if($null -ne $published_permission){
                                $new_permission.PermissionName = $published_permission.value;
                                $new_permission.PermissionDisplayName = $published_permission.adminConsentDisplayName;
                                $new_permission.PermissionDescription = $published_permission.adminConsentDescription;
                            }
                            elseif($null -ne $permission){
                                $new_permission.PermissionName = $permission.value;
                                $new_permission.PermissionDisplayName = $permission.displayName;
                                $new_permission.PermissionDescription = $permission.description;
                            }
                            #Add permission to array
                            [void]$all_permissions.Add($new_permission)
                        }
                    }
                }
            }
            #Return permissions
            return $all_permissions
        }
        catch{
            $msg = @{
			    MessageData = ($_);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'verbose';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDApplicationPermissionError');
		    }
		    Write-Verbose @msg
        }
    }
    End{
        #Nothing to do here
    }
}