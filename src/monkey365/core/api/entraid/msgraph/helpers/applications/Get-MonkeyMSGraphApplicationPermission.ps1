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

Function Get-MonkeyMSGraphApplicationPermission {
    <#
        .SYNOPSIS
		Function to get application permissions from Entra ID

        .DESCRIPTION
		Function to get application permissions from Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphApplicationPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Application")]
        [Object]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage="Add permission array to application")]
        [Switch]$AddToObject,

        [parameter(Mandatory=$false)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        If($APIVersion -eq 'beta'){
            $consentPath = 'publishedPermissionScopes'
        }
        Else{
            $consentPath = 'oauth2PermissionScopes'
        }
    }
    Process{
        Try{
            #Set nulls
            $servicePrincipals = $appRoleAssignment = $Oauth2Grants = $null
            #Set arrays
            $all_sp_permissions = [System.Collections.Generic.List[System.Object]]::new()
            $all_permissions = [System.Collections.Generic.List[System.Object]]::new()
            $allSps = [System.Collections.Generic.List[System.Object]]::new()
            #Get resource AppId
            $requiredResourceAccess = $InputObject | Select-Object -ExpandProperty requiredResourceAccess -ErrorAction Ignore
            #Get resourceAppId
            $resourceAppIds = $requiredResourceAccess| Select-Object -ExpandProperty resourceAppId -ErrorAction Ignore
            #Get Service principals
            ForEach($resourceAppId in @($resourceAppIds).Where({$null -ne $_})){
                #Get Service Principal
                $p = @{
                    Filter = ("appId eq '{0}'" -f $resourceAppId);
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $requiredSp = Get-MonkeyMSGraphServicePrincipal @p
                If($requiredSp){
                    #Add to array
                    [void]$allSps.Add($requiredSp);
                    #Add approles to array
                    #Add to array
                    If ($requiredSp.appRoles -is [System.Collections.IEnumerable] -and $requiredSp.appRoles -isnot [string]){
                        [void]$all_sp_permissions.AddRange($requiredSp.appRoles)
                    }
                    ElseIf ($requiredSp.appRoles.GetType() -eq [System.Management.Automation.PSCustomObject] -or $requiredSp.appRoles.GetType() -eq [System.Management.Automation.PSObject]) {
                        [void]$all_sp_permissions.Add($requiredSp.appRoles)
                    }
                    Else{
                        $msg = @{
                            MessageData = "Unable to recognize object from Entra Id";
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'Verbose';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('Monkey365UnrecognizedEnraIdObject');
                        }
                        Write-Verbose @msg
                    }
                }
            }
            If($null -ne $requiredResourceAccess -and $all_sp_permissions.Count -gt 0){
                #Get Service Principal from Application
                $p = @{
                    Filter = ("appId eq '{0}'" -f $InputObject.appId);
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $servicePrincipal = Get-MonkeyMSGraphServicePrincipal @p
                #Get Service Principal role assignment
                If($null -ne $servicePrincipal){
                    #Get Servcice Principal role assignment
                    $p = @{
                        ServicePrincipalId = $servicePrincipal.id;
                        ObjectType = "appRoleAssignments";
                        APIVersion = $APIVersion;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $appRoleAssignment = Get-MonkeyMSGraphServicePrincipal @p
                    #Get potential delegated permissions consent type through OauthGrants
                    $p = @{
                        Filter = ("clientId eq '{0}' and consentType eq 'AllPrincipals'" -f $servicePrincipal.id);
                        APIVersion = $APIVersion;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $Oauth2Grants = Get-MonkeyMSGraphOauth2PermissionGrant @p
                }
            }
            #Enumerate permissions
            If($null -ne $requiredResourceAccess){
                ForEach($resource in @($requiredResourceAccess).Where({$null -ne $_})){
                    #Get Id
                    $appId = $resource | Select-Object -ExpandProperty resourceAppId -ErrorAction Ignore
                    #Get permissions Ids
                    $permissions = $resource | Select-Object -ExpandProperty resourceAccess -ErrorAction Ignore
                    #Get service principal
                    $sp = $allSps.Where({$_.appId -eq $appId},[System.Management.Automation.WhereOperatorSelectionMode]::First);
                    If($sp.Count -eq 1 -and $null -ne $permissions){
                        $msg = @{
                            MessageData = ("Enumerating {0} application permissions for {1}" -f $InputObject.displayName,$sp.displayName);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'info';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('Monkey365ApplicationPermission');
                        }
                        Write-Information @msg
                        #Enumerate application permissions
                        ForEach($permission in @($permissions).Where({$null -ne $_ -and $_.type -eq 'Role'})){
                            #Search for permission
                            $perm = $all_sp_permissions.Where({$_.id -eq $permission.id},[System.Management.Automation.WhereOperatorSelectionMode]::First)
                            If($perm.Count -eq 1){
                                $newPermission = $perm | New-MonkeyApplicationPermissionObject
                                #Admin consent is required for Application permissions
                                $newPermission.adminConsentRequired = $true;
                                #Add Api name and service principal Id
                                $newPermission.apiName = $sp | Select-Object -ExpandProperty displayName -ErrorAction Ignore;
                                $newPermission.servicePrincipalId = $sp | Select-Object -ExpandProperty id -ErrorAction Ignore;
                                #Check if granted to organisation
                                $orgConsent = @($appRoleAssignment).Where({$_.appRoleId -eq $permission.Id},[System.Management.Automation.WhereOperatorSelectionMode]::First)
                                If($orgConsent.Count -eq 1){
                                    $newPermission.status = $true;
                                    $newPermission.grantedForCompany = $true;
                                }
                                Else{
                                    $newPermission.status = $false;
                                    $newPermission.grantedForCompany = $false;
                                }
                                [void]$all_permissions.Add($newPermission);
                            }
                            Else{
                                $msg = @{
                                    MessageData = ("Unrecognized permission {0} for {1}" -f $permission.id,$sp.displayName);
                                    callStack = (Get-PSCallStack | Select-Object -First 1);
                                    logLevel = 'warning';
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Tags = @('Monkey365ApplicationPermissionError');
                                }
                                Write-Warning @msg
                            }
                        }
                        #Enumerate delegation permissions
                        ForEach($permission in @($permissions).Where({$null -ne $_ -and $_.type -eq 'Scope'})){
                            #Set new permission
                            $newPermission = New-MonkeyApplicationPermissionObject
                            #Set properties
                            $newPermission.permissionType = "Delegated";
                            #Add Api name and service principal Id
                            $newPermission.apiName = $sp | Select-Object -ExpandProperty displayName -ErrorAction Ignore;
                            $newPermission.servicePrincipalId = $sp | Select-Object -ExpandProperty id -ErrorAction Ignore;
                            #Get sp perm
                            $perm = @($sp.($consentPath)).Where({$_.id -eq $permission.id},[System.Management.Automation.WhereOperatorSelectionMode]::First);
                            If($perm.Count -eq 1){
                                #Set properties
                                $newPermission.claimValue = $perm | Select-Object -ExpandProperty value -ErrorAction Ignore;
                                $newPermission.permissionDisplayName = $perm | Select-Object -ExpandProperty adminConsentDisplayName -ErrorAction Ignore;
                                $newPermission.permissionDescription = $perm | Select-Object -ExpandProperty adminConsentDescription -ErrorAction Ignore;
                                #Set if admin consent required
                                $type = $perm | Select-Object -ExpandProperty type -ErrorAction Ignore;
                                $adminConsent = 'Unknown';
                                If($null -ne $type){
                                    If($type.ToLower() -eq 'admin'){
                                        $adminConsent = $true;
                                    }
                                    ElseIf($type.ToLower() -eq 'user'){
                                        $adminConsent = $false;
                                    }
                                    Else{
                                        $adminConsent = 'Unknown';
                                    }
                                }
                                Else{
                                    $adminConsent = 'Unknown';
                                }
                                $newPermission.adminConsentRequired = $adminConsent;
                                If($newPermission.adminConsentRequired){
                                    #Check if granted for organisation
                                    If($null -ne $Oauth2Grants){
                                        $orgConsent = @($Oauth2Grants).Where({$_.scope.Trim().Split(' ') -contains $newPermission.claimValue},[System.Management.Automation.WhereOperatorSelectionMode]::First)
                                        If($orgConsent.Count -eq 1){
                                            $newPermission.status = $true;
                                            $newPermission.grantedForCompany = $true;
                                        }
                                        Else{
                                            $newPermission.status = $false;
                                            $newPermission.grantedForCompany = $false;
                                        }
                                    }
                                }
                                Else{#Probably admin consent is not required
                                    $newPermission.status = $true;
                                    $newPermission.grantedForCompany = $true;
                                }
                                #Add to array
                                [void]$all_permissions.Add($newPermission);
                            }
                            Else{
                                $msg = @{
                                    MessageData = ("Unrecognized permission {0} for {1}" -f $permission.id,$sp.displayName);
                                    callStack = (Get-PSCallStack | Select-Object -First 1);
                                    logLevel = 'warning';
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Tags = @('Monkey365ApplicationPermissionError');
                                }
                                Write-Warning @msg
                            }
                        }
                    }
                }
            }
            #Return object
            If($AddToObject.IsPresent){
                $InputObject | Add-Member -MemberType NoteProperty -Name permissions -Value $all_permissions -Force
                return $InputObject
            }
            Else{
                return $all_permissions
            }
        }
        Catch{
            $msg = @{
                MessageData = ($message.GenericObjectErrorMessage -f "get application permissions",$InputObject.displayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('EntraIDApplicationPermissionError');
            }
            Write-Warning @msg
            Write-Error $_.Exception.Message
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
}
