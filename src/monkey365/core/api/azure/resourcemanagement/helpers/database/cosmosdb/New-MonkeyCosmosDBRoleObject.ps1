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

Function New-MonkeyCosmosDBRoleObject {
<#
        .SYNOPSIS
		Create a new CosmosDB role object

        .DESCRIPTION
		Create a new CosmosDB role object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyCosmosDBRoleObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Cosmos role definition object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $roleObject = [ordered]@{
                id = $InputObject.Id;
                internalName = $InputObject.internalName;
		        name = $InputObject.roleName;
                type = $InputObject.type;
                assignableScopes = $InputObject.assignableScopes;
                permissions = $InputObject.permissions;
                users = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
                groups = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
                servicePrincipals = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
                effectiveMembers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
                effectiveUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
                duplicateUsers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
                totalActiveusers = $null;
                totalActiveMembers = $null;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $roleObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = $_;
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('CosmosDBRoleObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "CosmosDBRoleObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
