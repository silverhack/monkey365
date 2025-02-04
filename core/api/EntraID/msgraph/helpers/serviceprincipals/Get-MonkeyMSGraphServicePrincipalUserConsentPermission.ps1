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


Function Get-MonkeyMSGraphServicePrincipalUserConsentPermission{
    <#
        .SYNOPSIS
		Get user consent permissions from service principal

        .DESCRIPTION
		Get user consent permissions from service principal

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphServicePrincipalUserConsentPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
	Param (
        [parameter(Mandatory=$false)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        #Set filter
        $sp_filter = "tags/Any(monkeysp: monkeysp eq 'WindowsAzureActiveDirectoryIntegratedApp')"
    }
    Process{
        try{
            $all_permissions = New-Object System.Collections.Generic.List[System.Object]
            #Get all service principals
            $params = @{
                Filter = $sp_filter;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $all_sps = Get-MonkeyMSGraphAADServicePrincipal @params
            foreach($sp in $all_sps){
                $new_filter = ("clientId eq '{0}'" -f $sp.id);
                $params = @{
                    Filter = $new_filter;
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $Oauth2Grants = Get-MonkeyMSGraphOauth2PermissionGrant @params
                foreach($grant in $Oauth2Grants){
                    $ResourceDisplayName = $PrincipalDisplayName = $PrincipalUpn = $spObject = $userObject = $null
                    $objectIds = New-Object System.Collections.Generic.List[System.String]
                    #Get Scope
                    $scopes = $grant.scope.Trim().Split();
                    #Get PrincipalId and ResourceobjectId
                    $PrincipalId = $grant.principalId
                    if($null -ne $PrincipalId){
                        [void]$objectIds.Add($PrincipalId)
                    }
                    #Get Resource Object Id
                    $roid = $grant.resourceId
                    if($null -ne $roid){
                        [void]$objectIds.Add($roid)
                    }
                    #Get Objects by Id
                    $params = @{
                        Ids = $objectIds;
                        APIVersion = $APIVersion;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $_objects = Get-MonkeyMSGraphDirectoryObjectById @params
                    if($_objects){
                        $spObject = $_objects | Where-Object {$_.'@odata.type' -eq '#microsoft.graph.servicePrincipal'}
                        $userObject = $_objects | Where-Object {$_.'@odata.type' -eq '#microsoft.graph.user'}
                        if($spObject){
                            #Get sp displayName
                            $ResourceDisplayName = $spObject.appDisplayName
                        }
                        if($userObject){
                            #Get sp displayName
                            $PrincipalDisplayName = $userObject.displayName
                            $PrincipalUpn = $userObject.userPrincipalName
                        }
                    }
                    foreach($scope in $scopes){
                        if($null -ne $spObject){
                            #Get permission displayName
                            $perm = $spObject.appRoles | Where-Object {$_.value -eq $scope}
                        }
                        #Create new PsObject
                        $new_permission = New-MonkeyAADServicePrincipalPermissionObject -ServicePrincipal $sp
                        #Add Permission
                        $new_permission.ConsentType = $grant.consentType;
                        $new_permission.PermissionId = $grant.id;
                        $new_permission.PermissionName = $scope;
                        $new_permission.ResourceObjectId = $grant.resourceId;
                        $new_permission.ResourceDisplayName = $ResourceDisplayName;
                        $new_permission.PrincipalObjectId = $grant.principalId;
                        $new_permission.PrincipalDisplayName = $PrincipalDisplayName;
                        $new_permission.PrincipalUPN = $PrincipalUpn;
                        $new_permission.PrincipalObjectId = $grant.principalId;
                        if($null -ne $perm){
                            $new_permission.PermissionDisplayName = $perm.displayName;
                            $new_permission.PermissionDescription = $perm.description;
                        }
                        #Add to array
                        [void]$all_permissions.Add($new_permission)
                    }
                }
            }
            return $all_permissions
        }
        catch{
            $msg = @{
			    MessageData = ($message.MSGraphDirectoryObjectError);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'verbose';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('DirectoryObjectError');
		    }
		    Write-Verbose @msg
            $msg.MessageData = $_
            $msg.Tags+= "DirectoryObjectError"
		    Write-Verbose @msg
        }
    }
    End{
        #Nothing to do here
    }
}


