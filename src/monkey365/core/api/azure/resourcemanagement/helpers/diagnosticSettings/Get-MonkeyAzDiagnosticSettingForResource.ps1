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

Function Get-MonkeyAzDiagnosticSettingForResource {
    <#
        .SYNOPSIS
		Get diagnostic settings by resource

        .DESCRIPTION
		Get diagnostic settings by resource

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzDiagnosticSettingForResource
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage= 'Azure Object')]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Attach to object")]
        [Switch]$AddToObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2021-05-01-preview"
    )
    Process{
        try{
            $Id = $InputObject | Select-Object -ExpandProperty id -ErrorAction Ignore
            If($null -ne $Id){
                $p = @{
			        Id = $Id;
                    Resource = 'providers/microsoft.insights/diagnosticSettings';
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $_diag = Get-MonkeyAzObjectById @p
                #Format object
                $_diag = New-MonkeyDiagnosticSettingObject -InputObject $_diag
                If($AddToObject.IsPresent){
                    $InputObject | Add-Member -MemberType NoteProperty -Name diagnosticSettings -Value $_diag -Force
                    return $InputObject
                }
                Else{
                    return $_diag
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
