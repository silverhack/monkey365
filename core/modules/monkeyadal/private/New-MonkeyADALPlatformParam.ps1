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

Function New-MonkeyADALPlatformParam{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyADALPlatformParam
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "Select prompt behavior")]
        [ValidateSet("Always", "Auto", "Never", "RefreshSession","SelectAccount")]
        [String]$PromptBehavior="Auto",

        [Parameter(Mandatory=$false, HelpMessage="Force Authentication Context. Only valid for user&password auth method")]
        [Switch]$ForceAuth
    )
    try{
        #Prompt behavior
        #https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.promptbehavior?view=azure-dotnet
        $prompt = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior
        if([string]::IsNullOrEmpty($PromptBehavior)){
            $prompt.value__ = 1
        }
        elseif($ForceAuth -or [PromptBehavior]$PromptBehavior -eq "Always"){
            $prompt.value__ = 1
        }
        else{
            $prompt.value__ = [PromptBehavior]$PromptBehavior
        }
        $platformParameters = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList $prompt
        return $platformParameters
    }
    catch{
        Write-Verbose -Message $_
    }
}
