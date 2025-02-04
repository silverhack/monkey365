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

Function New-MonkeyEntraIDRoleObject {
<#
        .SYNOPSIS
		Create a new Entra ID role object

        .DESCRIPTION
		Create a new Entra ID role object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyEntraIDRoleObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Entra ID role assignment object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $EntraIdRoleObject = [ordered]@{
                id = $InputObject.roleDefinition.Id;
		        name = $InputObject.roleDefinition.displayName;
                displayName = $InputObject.roleDefinition.displayName;
                description = $InputObject.roleDefinition.description;
                isBuiltIn = $InputObject.roleDefinition.isBuiltIn;
                isEnabled = $InputObject.roleDefinition.isEnabled;
                resourceScopes = $InputObject.roleDefinition.resourceScopes;
                templateId = $InputObject.roleDefinition.templateId;
                version = $InputObject.roleDefinition.version;
                rolePermissions = $InputObject.roleDefinition.rolePermissions;
                users = $null;
                groups = $null;
                servicePrincipals = $null;
                effectiveMembers = $null;
                effectiveUsers = $null;
                duplicateUsers = $null;
                totalActiveusers = $null;
                totalActiveMembers = $null;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $EntraIdRoleObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Entra ID role object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('EntraIDRoleObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "EntraIDRoleObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}

