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

Function Update-ServicePrincipal {
<#
        .SYNOPSIS
		Update service principal object with sign-in activity information, foreign app, etc..

        .DESCRIPTION
		Update service principal object with sign-in activity information, foreign app, etc..

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-ServicePrincipal
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Service Principal Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false,HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        $foreign = $signInActivity = $null
        $appOwnerOrganizationId = $InputObject | Select-Object -ExpandProperty appOwnerOrganizationId -ErrorAction Ignore
        If($appOwnerOrganizationId -eq $O365Object.TenantId){
            $foreign = $false
        }
        Else{
            $foreign = $True
        }
        #Add to object 
        $InputObject | Add-Member -MemberType NoteProperty -Name foreign -Value $foreign -Force
        #Get last sign in activity
        $appId = $InputObject | Select-Object -ExpandProperty appId -ErrorAction Ignore
        If($null -ne $appId){
            $signInActivity = Get-MonkeyMSGraphServicePrincipalSignInActivity -AppId $appId
            #Add to object
            $InputObject | Add-Member -MemberType NoteProperty -Name signInActivity -Value $signInActivity -Force
        }
        #return object
        $InputObject
    }
}
