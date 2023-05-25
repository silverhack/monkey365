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

Function New-MonkeyAADAppPermissionObject {
<#
        .SYNOPSIS
		Create a new Azure AD application permission object

        .DESCRIPTION
		Create a new Azure AD application permission object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyAADAppPermissionObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True)]
        [Object]$Application
    )
    Process{
        try{
            #Create ordered dictionary
            $new_permission = [ordered]@{
                ApplicationDisplayName = $Application.displayName;
		        ApplicationClientId = $Application.appId;
		        ApplicationObjectId = $Application.id;
                ResourceObjectId = $null;
                ResourceDisplayName = $null;
                ResourceAppId = $null;
                PermissionType = $null;
		        PermissionId = $null;
                PermissionName = $null;
                PermissionDisplayName = $null;
                PermissionDescription = $null;
                GrantType = $null;
            }
            #Create PsObject
            $perm_obj = New-Object -TypeName PsObject -Property $new_permission
            #return object
            return $perm_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.AADAppPermissionObjectError -f $Application.displayName);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $InformationAction;
			    Tags = @('AADApplicationPermissionObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "AADApplicationPermissionObjectVerbose"
		    Write-Verbose @msg
        }
    }
}