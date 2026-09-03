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

Function New-MonkeyAzureRoleObject {
<#
        .SYNOPSIS
		Create a new Azure role object

        .DESCRIPTION
		Create a new Azure role object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyAzureRoleObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Azure role definition object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Basic Object")]
        [Switch]$Basic,

        [parameter(Mandatory=$false, HelpMessage="Identity Object")]
        [Switch]$Identity
    )
    Process{
        try{
            If($PSBoundParameters.ContainsKey('Basic') -and $PSBoundParameters['Basic'].IsPresent){
                #Create ordered dictionary
                $azureRoleObject = [ordered]@{
                    id = $InputObject.Id;
                    type = $InputObject.type;
		            name = $InputObject.properties.roleName;
                    displayName = $InputObject.properties.roleName;
                    description = $InputObject.properties.description;
                    templateId = $InputObject.name;
                    isBuiltIn = If($InputObject.properties.type.ToLower() -eq 'builtinrole'){$True}Else{$false};
                    roleType = $InputObject.properties.type;
                    assignableScopes = $InputObject.properties.assignableScopes;
                    permissions = $InputObject.properties.permissions;
                    createdOn = $InputObject.properties.createdOn;
                    updatedOn = $InputObject.properties.updatedOn;
                    createdBy = $InputObject.properties.createdBy;
                    updatedBy = $InputObject.properties.updatedBy;
                }
            }
            ElseIf($PSBoundParameters.ContainsKey('Identity') -and $PSBoundParameters['Identity'].IsPresent){
                #Create ordered dictionary
                $azureRoleObject = [ordered]@{
                    id = $InputObject.Id;
                    type = $InputObject.type;
		            name = $InputObject.properties.roleName;
                    displayName = $InputObject.properties.roleName;
                    description = $InputObject.properties.description;
                    templateId = $InputObject.name;
                    isBuiltIn = If($InputObject.properties.type.ToLower() -eq 'builtinrole'){$True}Else{$false};
                    roleType = $InputObject.properties.type;
                    assignableScopes = $InputObject.properties.assignableScopes;
                    permissions = $InputObject.properties.permissions;
                    createdOn = $InputObject.properties.createdOn;
                    updatedOn = $InputObject.properties.updatedOn;
                    createdBy = $InputObject.properties.createdBy;
                    updatedBy = $InputObject.properties.updatedBy;
                    principalId = $null;
                    principalType = $null;
                    scope = $null;
                    condition = $null;
                    conditionVersion = $null;
                    delegatedManagedIdentityResourceId = $null;
                    assignmentDescription = $null;
                    roleCreatedOn = $null;
                    roleUpdatedOn = $null;
                    roleCreatedBy = $null;
                    roleUpdatedBy = $null;
                }
            }
            Else{
                #Create ordered dictionary
                $azureRoleObject = [ordered]@{
                    id = $InputObject.Id;
                    type = $InputObject.type;
		            name = $InputObject.properties.roleName;
                    displayName = $InputObject.properties.roleName;
                    description = $InputObject.properties.description;
                    templateId = $InputObject.name;
                    isBuiltIn = If($InputObject.properties.type.ToLower() -eq 'builtinrole'){$True}Else{$false};
                    roleType = $InputObject.properties.type;
                    assignableScopes = $InputObject.properties.assignableScopes;
                    permissions = $InputObject.properties.permissions;
                    createdOn = $InputObject.properties.createdOn;
                    updatedOn = $InputObject.properties.updatedOn;
                    createdBy = $InputObject.properties.createdBy;
                    updatedBy = $InputObject.properties.updatedBy;
                    users = $null;
                    groups = $null;
                    servicePrincipals = $null;
                    effectiveMembers = $null;
                    effectiveUsers = $null;
                    duplicateUsers = $null;
                    duplicateObjects = $null;
                    totalActiveusers = $null;
                    totalActiveMembers = $null;
                }
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $azureRoleObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Azure role object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('AzureRoleObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "AzureRoleObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
