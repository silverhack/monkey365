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

function Get-MonkeyAzRBACForManagedIdentity{
    <#
        .SYNOPSIS
        Get Role assignments for managed identities

        .DESCRIPTION
        Get Role assignments for managed identities

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRBACForManagedIdentity
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Object")]
        [Object]$InputObject
    )
    Begin{
        #Set array
        $allIdentities = [System.Collections.Generic.List[System.Object]]::new()
        #Get Config
        $_config = @($O365Object.internal_config.ResourceManager).Where{$_.Name -eq "managedIdentity"} | Select-Object -ExpandProperty resource
    }
    Process{
        Try{
            ForEach($_object in @($InputObject)){
                $identity = $_object | Select-Object -ExpandProperty identity -ErrorAction Ignore
                If($null -ne $identity){
                    If($identity.type.ToLower() -eq "userassigned"){
                        $identities = $identity.userAssignedIdentities.PsObject.Properties | Select-Object -ExpandProperty Name -ErrorAction Ignore
                        #Get managed user identities
                        ForEach($_identity in @($identities)){
                            $p = @{
	                            Id = $_identity;
	                            APIVersion = $_config.api_version;
	                            Verbose = $O365Object.Verbose;
	                            Debug = $O365Object.Debug;
	                            InformationAction = $O365Object.InformationAction;
                            }
                            $_id = Get-MonkeyAzObjectById @p
                            If($null -ne $_id){
                                $_userIdentity = [PsCustomObject]@{
                                    id = $_id.id;
                                    name = $_id.name;
                                    location = $_id.location;
                                    tags = $_id | Select-Object -ExpandProperty tags -ErrorAction Ignore
                                    type = $_id.type;
                                    tenantId = $_id.properties.tenantId;
                                    principalId = $_id.properties.principalId;
                                    clientId = $_id.properties.clientId;
                                    isolationScope = $_id.properties.isolationScope;
                                    roleAssignment = (Get-MonkeyAzIAMPermission -PrincipalId $_id.properties.principalId -AtScope)
                                }
                                #Add to array
                                [void]$allIdentities.Add($_userIdentity);
                            }
                        }
                    }
                    ElseIf($identity.type.ToLower() -eq "systemassigned"){
                        $identities = $identity | Select-Object -ExpandProperty principalId
                        ForEach($_identity in @($identities)){
                            #Get Service principal
                            $sp = Get-MonkeyMSGraphServicePrincipal -ServicePrincipalId $_identity
                            If($null -ne $sp){
                                $_systemIdentity = [PsCustomObject]@{
                                    id = $sp.id;
                                    name = $sp.displayName;
                                    location = $null;
                                    tags = $null;
                                    type = $sp.servicePrincipalType;
                                    tenantId = $identity.tenantId;
                                    principalId = $identity.principalId;
                                    clientId = $sp.appId;
                                    isolationScope = $null;
                                    roleAssignment = (Get-MonkeyAzIAMPermission -PrincipalId $_identity -AtScope)
                                }
                                #Add to array
                                [void]$allIdentities.Add($_systemIdentity);
                            }
                        }
                    }
                    ElseIf($identity.type.ToLower().Contains('systemassigned') -and $identity.type.ToLower().Contains('userassigned')){
                        #Get PrincipalId
                        $identities = $identity | Select-Object -ExpandProperty principalId
                        ForEach($_identity in @($identities)){
                            #Get Service principal
                            $sp = Get-MonkeyMSGraphServicePrincipal -ServicePrincipalId $_identity
                            If($null -ne $sp){
                                $_systemIdentity = [PsCustomObject]@{
                                    id = $sp.id;
                                    name = $sp.displayName;
                                    location = $null;
                                    tags = $null;
                                    type = $sp.servicePrincipalType;
                                    tenantId = $identity.tenantId;
                                    principalId = $identity.principalId;
                                    clientId = $sp.appId;
                                    isolationScope = $null;
                                    roleAssignment = (Get-MonkeyAzIAMPermission -PrincipalId $_identity -AtScope)
                                }
                                #Add to array
                                [void]$allIdentities.Add($_systemIdentity);
                            }                    
                        }
                        #Get user managed identities
                        $identities = $identity.userAssignedIdentities.PsObject.Properties | Select-Object -ExpandProperty Name -ErrorAction Ignore
                        #Get managed user identities
                        ForEach($_identity in @($identities)){
                            $p = @{
	                            Id = $_identity;
	                            APIVersion = $_config.api_version;
	                            Verbose = $O365Object.Verbose;
	                            Debug = $O365Object.Debug;
	                            InformationAction = $O365Object.InformationAction;
                            }
                            $_id = Get-MonkeyAzObjectById @p
                            If($null -ne $_id){
                                $_userIdentity = [PsCustomObject]@{
                                    id = $_id.id;
                                    name = $_id.name;
                                    location = $_id.location;
                                    tags = $_id | Select-Object -ExpandProperty tags -ErrorAction Ignore
                                    type = $_id.type;
                                    tenantId = $_id.properties.tenantId;
                                    principalId = $_id.properties.principalId;
                                    clientId = $_id.properties.clientId;
                                    isolationScope = $_id.properties.isolationScope;
                                    roleAssignment = (Get-MonkeyAzIAMPermission -PrincipalId $_id.properties.principalId -AtScope)
                                }
                                #Add to array
                                [void]$allIdentities.Add($_userIdentity);
                            }
                        }
                    }
                }
            }
            Write-Output $allIdentities -NoEnumerate
        }
        Catch{
            Write-Error $_.Exception
        }
    }
}
