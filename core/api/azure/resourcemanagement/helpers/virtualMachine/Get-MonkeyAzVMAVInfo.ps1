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

Function Get-MonkeyAzVMAVInfo {
    <#
        .SYNOPSIS
		Get Azure VM Antimalware status

        .DESCRIPTION
		Get Azure VM Antimalware status

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVMAVInfo
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
            If($null -ne $InputObject.PsObject.Properties.Item('resources') -and $null -ne $InputObject.resources){
                $av = @($InputObject.resources).Where({($_.Id -match "IaaSAntimalware" -or $_.Id -match "MDE.Windows" -or $_.Id -match "MDE.Linux") -and ($_.properties.provisioningState -ne 'Failed')})
                if($av.Count -gt 0){
                    $InputObject.isAVAgentInstalled = $True
                }
                else{
                    $InputObject.isAVAgentInstalled = $false
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
