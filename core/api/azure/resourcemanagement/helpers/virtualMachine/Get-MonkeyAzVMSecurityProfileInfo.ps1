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

Function Get-MonkeyAzVMSecurityProfileInfo {
    <#
        .SYNOPSIS
		Get Azure VM Security profile info

        .DESCRIPTION
		Get Azure VM Security profile info


        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVMSecurityProfileInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="VM object")]
        [Object]$InputObject
    )
    Process{
        try{
            $securityProfile = $InputObject.properties | Select-Object -ExpandProperty securityProfile -ErrorAction Ignore
            If($null -ne $securityProfile){
                $InputObject.securityProfile.encryptionAtHost = $securityProfile.encryptionAtHost;
                $InputObject.securityProfile.securityType.ConfidentialVM = $securityProfile.securityType.ConfidentialVM;
                $InputObject.securityProfile.securityType.TrustedLaunch = $securityProfile.securityType.TrustedLaunch;
                $InputObject.securityProfile.uefiSettings.secureBootEnabled = $securityProfile.uefiSettings.secureBootEnabled;
                $InputObject.securityProfile.uefiSettings.vTpmEnabled = $securityProfile.uefiSettings.vTpmEnabled;
                $InputObject.securityProfile.rawObject = $securityProfile
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}

