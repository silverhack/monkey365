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

Function New-MonkeyEnterpriseAppUserConsentPermissionObject {
<#
        .SYNOPSIS
		Create a new Entra ID Enterprise application user consent permission object

        .DESCRIPTION
		Create a new Entra ID Enterprise application user consent permission object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyEnterpriseAppUserConsentPermissionObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [AllowNull()]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $new_permission = [ordered]@{
                id = $null;
                apiName = $InputObject | Select-Object -ExpandProperty displayName -ErrorAction Ignore;
		        servicePrincipalId = $InputObject | Select-Object -ExpandProperty id -ErrorAction Ignore;
                PrincipalObjectId = $null;
                PrincipalDisplayName = $null;
                PrincipalUPN = $null;
		        ConsentType = $null;
                claimValue = $null;
                permissionDisplayName = $null;
                permissionDescription = $null;
                permissionLevel = $null;
                permissionType = $null;
                grantedThrough = $null;
            }
            #Create PsObject
            $perm_obj = New-Object -TypeName PsObject -Property $new_permission
            #return object
            return $perm_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "enterprise application user consent permission object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('EIDEnterpriseAppUSerConsentPermissionObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "EIDEnterpriseAppUSerConsentPermissionObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
