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

Function Get-MonkeyMSGraphEnterpriseApplicationPermission {
    <#
        .SYNOPSIS
		Function to get service principal permissions from Entra ID

        .DESCRIPTION
		Function to get service principal permissions from Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphEnterpriseApplicationPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Service Principal")]
        [Object]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage="Add permission array to service principal")]
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
            $servicePrincipals = $null
            #Set arrays
            $all_sp_permissions = [System.Collections.Generic.List[System.Object]]::new()
            $allPermissions = [System.Collections.Generic.List[System.Object]]::new()
            #Get delegated permissions consent type through OauthGrants
            $p = @{
                Filter = ("clientId eq '{0}' and consentType eq 'AllPrincipals'" -f $InputObject.id);
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $Oauth2Grants = Get-MonkeyMSGraphOauth2PermissionGrant @p
            #Get Servcice Principal role assignment
            $p = @{
                ServicePrincipalId = $InputObject.id;
                ObjectType = "appRoleAssignments";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $appRoleAssignment = Get-MonkeyMSGraphServicePrincipal @p
            #Extract resourceId from appRoleAssignments
            $resourceIds = $appRoleAssignment | Select-Object -ExpandProperty resourceId -ErrorAction Ignore -Unique
            If($null -ne $resourceIds){
                #Get Objects by Id
                $p = @{
                    Ids = $resourceIds;
                    Select = "id","appDisplayName","displayName","appRoles",$consentPath
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $servicePrincipals = Get-MonkeyMSGraphDirectoryObjectById @p
                ForEach($raw_sp in @($servicePrincipals).Where({$null -ne $_})){
                    #Get appRoles
                    $appRoles = $raw_sp | Select-Object -ExpandProperty appRoles -ErrorAction Ignore
                    #Add to array
                    If ($appRoles -is [System.Collections.IEnumerable] -and $appRoles -isnot [string]){
                        [void]$all_sp_permissions.AddRange($appRoles)
                    }
                    ElseIf ($appRoles.GetType() -eq [System.Management.Automation.PSCustomObject] -or $appRoles.GetType() -eq [System.Management.Automation.PSObject]) {
                        [void]$all_sp_permissions.Add($appRoles)
                    }
                    Else{
                        $msg = @{
                            MessageData = ($message.GenericObjectErrorMessage -f "recognize",$InputObject.displayName);
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
            #Get application permissions
            If($null -ne $appRoleAssignment -and $all_sp_permissions.Count -gt 0){
                #Translate permission objects
                ForEach($roleAssignment in @($appRoleAssignment).Where({$null -ne $_})){
                    $newPermission = $roleAssignment | New-MonkeyEnterpriseApplicationPermissionObject
                    #Search for permission
                    $perm = $all_sp_permissions.Where({$_.id -eq $roleAssignment.appRoleId},[System.Management.Automation.WhereOperatorSelectionMode]::First)
                    If($perm.Count -eq 1){
                        #Add permission to object
                        $newPermission.claimValue = ($perm | Select-Object -ExpandProperty value -ErrorAction Ignore);
                        $newPermission.permissionDisplayName = ($perm | Select-Object -ExpandProperty displayName -ErrorAction Ignore);
                        $newPermission.permissionDescription = ($perm | Select-Object -ExpandProperty description -ErrorAction Ignore);
                        $newPermission.permissionType = ($perm | Select-Object -ExpandProperty origin -ErrorAction Ignore);
                        $newPermission.grantedThrough = "Admin Consent";
                        $newPermission.grantedBy = "An administrator";
                    }
                    Else{
                        $msg = @{
                            MessageData = ($message.GenericInputObjectErrorMessage -f ("{0} permission reference" -f $roleAssignment.appRoleId),$InputObject.displayName);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'Verbose';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('Monkey365ApplicationPermissionReferenceError');
                        }
                        Write-Verbose @msg
                    }
                    #Add to object
                    [void]$allPermissions.Add($newPermission);
                }
            }
            #Get delegated permissions
            If($null -ne $Oauth2Grants -and $null -ne $servicePrincipals){
                #Get Delegated permissions
                ForEach($grant in @($Oauth2Grants).Where({$null -ne $_})){
                    $sp = $null;
                    #Get service Principal
                    $sp = @($servicePrincipals).Where({$_.id -eq $grant.resourceId},[System.Management.Automation.WhereOperatorSelectionMode]::First);
                    If($sp.Count -eq 0){
                        #Try to get service principal directly
                        $p = @{
                            ServicePrincipalId = $grant.resourceId;
                            APIVersion = $APIVersion;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $sp = Get-MonkeyMSGraphServicePrincipal @p
                    }
                    If(@($sp).Count -eq 1){
                        #Iterate over scopes
                        ForEach($scope in $grant.scope.Trim().Split(' ')){
                            $newPermission = New-MonkeyEnterpriseApplicationPermissionObject
                            $newPermission.id = $grant | Select-Object -ExpandProperty id -ErrorAction Ignore
                            $newPermission.apiName = $sp | Select-Object -ExpandProperty displayName -ErrorAction Ignore
                            $newPermission.servicePrincipalId = $grant | Select-Object -ExpandProperty resourceId -ErrorAction Ignore
                            $newPermission.permissionType = "Delegated";
                            $newPermission.grantedThrough = "Admin Consent";
                            $newPermission.grantedBy = "An administrator";
                            #Get permission
                            $perm = @($sp.($consentPath)).Where({$_.value -eq $scope.Trim()},[System.Management.Automation.WhereOperatorSelectionMode]::First);
                            If($perm.Count -gt 0){
                                $newPermission.claimValue = $perm | Select-Object -ExpandProperty value -ErrorAction Ignore
                                $newPermission.permissionDisplayName = $perm | Select-Object -ExpandProperty adminConsentDisplayName -ErrorAction Ignore
                                $newPermission.permissionDescription = $perm | Select-Object -ExpandProperty adminConsentDescription -ErrorAction Ignore
                            }
                            Else{
                                $msg = @{
                                    MessageData = ($message.GenericInputObjectErrorMessage -f ("get {0} permission reference for {1} and " -f $scope.Trim(),$InputObject.displayName),$sp.displayName);
                                    callStack = (Get-PSCallStack | Select-Object -First 1);
                                    logLevel = 'Verbose';
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Tags = @('Monkey365DelegatedPermissionReferenceError');
                                }
                                Write-Verbose @msg
                                #FallBack with scope permission
                                $newPermission.claimValue = $scope.Trim();
                            }
                            #Add to object
                            [void]$allPermissions.Add($newPermission)
                        }
                    }
                    Else{
                        $msg = @{
                            MessageData = ($message.GenericInputObjectErrorMessage -f "get service principal",$grant.resourceId);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'Warning';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('Monkey365ResourceIdReferenceError');
                        }
                        Write-Warning @msg
                    }
                }
            }
            #Return object
            If($AddToObject.IsPresent){
                $InputObject | Add-Member -MemberType NoteProperty -Name permissions -Value $allPermissions -Force
                return $InputObject
            }
            Else{
                return $allPermissions
            }
        }
        Catch{
            $msg = @{
                MessageData = ($message.GenericObjectErrorMessage -f "get enterprise application permissions",$InputObject.displayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('EntraIDEnterpriseApplicationPermissionError');
            }
            Write-Warning @msg
            Write-Error $_.Exception.Message
            $msg = @{
			    MessageData = ($_);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'verbose';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDEnterpriseApplicationPermissionError');
		    }
		    Write-Verbose @msg
        }
    }
}
