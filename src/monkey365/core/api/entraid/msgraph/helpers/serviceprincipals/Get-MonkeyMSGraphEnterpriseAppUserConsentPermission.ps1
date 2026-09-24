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

Function Get-MonkeyMSGraphEnterpriseAppUserConsentPermission {
    <#
        .SYNOPSIS
		Function to get service principal user consent delegated permissions from Entra ID

        .DESCRIPTION
		Function to get service principal user consent delegated permissions from Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphEnterpriseAppUserConsentPermission
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
        #Set array for caching
        $spCache = [System.Collections.Generic.List[System.Object]]::new()
    }
    Process{
        Try{
            #Set nulls
            $servicePrincipals = $null
            #Set arrays
            $all_permissions = [System.Collections.Generic.List[System.Object]]::new()
            #Get delegated permissions consent type through OauthGrants
            $p = @{
                Filter = ("clientId eq '{0}' and consentType eq 'Principal'" -f $InputObject.id);
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $Oauth2Grants = Get-MonkeyMSGraphOauth2PermissionGrant @p
            #Iterate over all grants
            ForEach($grant in @($Oauth2Grants).Where({$null -ne $_})){
                #Get related Service Principal
                $sp = $spCache.Where({$null -ne $_ -and $_.id -eq $grant.resourceId},[System.Management.Automation.WhereOperatorSelectionMode]::First);
                If($sp.Count -eq 0){
                    #Get Service principal
                    $p = @{
                        Ids = $grant.resourceId;
                        Select = "id","appId","appDisplayName","displayName","appRoles",$consentPath
                        APIVersion = $APIVersion;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $sp = Get-MonkeyMSGraphDirectoryObjectById @p
                    If($null -ne $sp){
                        #Add to cache
                        [void]$spCache.Add($sp);
                    }
                }
                Else{
                    #Get the first element
                    $sp = $sp[0];
                }
                #Get principal
                $p = @{
                    Ids = $grant.principalId;
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $principal = Get-MonkeyMSGraphDirectoryObjectById @p
                If($null -ne $sp -and $null -ne $principal){
                    #Iterate over scopes
                    ForEach($scope in $grant.scope.Trim().Split(' ')){
                        #Create new PsObject
                        $newPermission = $sp | New-MonkeyEnterpriseAppUserConsentPermissionObject
                        $newPermission.grantedThrough = "User Consent";
                        $newPermission.permissionType = "Delegated"
                        #Get permission
                        $perm = @($sp.($consentPath)).Where({$_.value -eq $scope.Trim()},[System.Management.Automation.WhereOperatorSelectionMode]::First);
                        #Add Permission
                        $newPermission.consentType = $grant | Select-Object -ExpandProperty consentType -ErrorAction Ignore
                        $newPermission.id = $grant | Select-Object -ExpandProperty id -ErrorAction Ignore
                        $newPermission.PrincipalObjectId = $grant | Select-Object -ExpandProperty principalId -ErrorAction Ignore;
                        $newPermission.PrincipalDisplayName = $principal | Select-Object -ExpandProperty displayName -ErrorAction Ignore;
                        $newPermission.PrincipalUPN = $principal | Select-Object -ExpandProperty userPrincipalName -ErrorAction Ignore;
                        $newPermission.PrincipalObjectId = $grant.principalId;
                        If($perm.Count -eq 1){
                            $newPermission.permissionLevel = $perm | Select-Object -ExpandProperty type -ErrorAction Ignore
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
                        #Add to array
                        [void]$all_permissions.Add($newPermission)
                    }
                }
            }
            #Return object
            If($AddToObject.IsPresent){
                $InputObject | Add-Member -MemberType NoteProperty -Name delegatedPermissions -Value $all_permissions -Force
                return $InputObject
            }
            Else{
                return $all_permissions
            }
        }
        Catch{
            $msg = @{
                MessageData = ($message.GenericObjectErrorMessage -f "get enterprise application user consent permissions",$InputObject.displayName);
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
