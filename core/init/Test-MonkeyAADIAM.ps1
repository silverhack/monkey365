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

Function Test-MonkeyAADIAM {
    <#
        .SYNOPSIS
		Check if current user has a specific role in Azure AD

        .DESCRIPTION
		Check if current user has a specific role in Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-MonkeyAADIAM
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [OutputType([System.Boolean])]
	[CmdletBinding(DefaultParameterSetName = 'RoleId')]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'RoleId')]
        [String]$RoleTemplateId = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451', # Global reader

        [Parameter(Mandatory=$false, ParameterSetName = 'Role')]
        [String]$RoleName
    )
    try{
        if($null -ne $O365Object.aadPermissions){
            if($PSCmdlet.ParameterSetName -eq 'RoleId'){
                if($O365Object.aadPermissions.directoryRoleInfo | Where-Object {$_.roleTemplateId -eq $RoleTemplateId}){
                    return $true
                }
                else{
                    return $false
                }
            }
            elseif($PSCmdlet.ParameterSetName -eq 'Role'){
                if($O365Object.aadPermissions.directoryRoleInfo | Where-Object {$_.displayName -eq $RoleName}){
                    return $true
                }
                else{
                    return $false
                }
            }
        }
    }
    catch{
        Write-Error $_
    }
}