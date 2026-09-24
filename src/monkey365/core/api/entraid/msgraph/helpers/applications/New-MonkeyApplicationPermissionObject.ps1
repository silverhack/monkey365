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

Function New-MonkeyApplicationPermissionObject {
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
            File Name	: New-MonkeyApplicationPermissionObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $new_permission = [ordered]@{
                id = $InputObject | Select-Object -ExpandProperty id -ErrorAction Ignore;
                apiName = $null;
	            servicePrincipalId = $null;
	            claimValue = $InputObject | Select-Object -ExpandProperty value -ErrorAction Ignore;
                adminConsentRequired = $null;
                permissionDisplayName = $InputObject | Select-Object -ExpandProperty displayName -ErrorAction Ignore;
                permissionDescription = $InputObject | Select-Object -ExpandProperty description -ErrorAction Ignore;
                permissionType = $InputObject | Select-Object -ExpandProperty origin -ErrorAction Ignore;
                status = $null;
                grantedForCompany = $null;
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
			    InformationAction = $O365Object.InformationAction;
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
