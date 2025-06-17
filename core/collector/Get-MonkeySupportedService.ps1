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

Function Get-MonkeySupportedService{
    <#
        .SYNOPSIS
        Get supported services from installed plugins
        .DESCRIPTION
        Get supported services from installed plugins
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySupportedService
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'EntraID')]
	Param(
		[Parameter(Mandatory = $true, ParameterSetName = 'Azure', HelpMessage = "Azure supported services")]
		[Switch]$Azure,

        [Parameter(Mandatory = $true, ParameterSetName = 'Microsoft365', HelpMessage = "Microsoft 365 supported services")]
		[Switch]$Microsoft365
	)
    Process{
        Try{
            $p = @{
                Provider = $PSCmdlet.ParameterSetName;
            }
            $collectorsMetadata = Get-MetadataFromCollector @p
            If($null -ne $collectorsMetadata){
                If($PSCmdlet.ParameterSetName -eq 'Azure'){
                    $selectedCollectors = $collectorsMetadata | Select-Object -ExpandProperty Group | Sort-Object -Unique
                    $selectedCollectors =, "All" + $selectedCollectors
                    $selectedCollectors = $selectedCollectors -replace '"', ""
                    return $selectedCollectors
                }
                Else{
                    $selectedCollectors = $collectorsMetadata | Select-Object -ExpandProperty Group | Sort-Object -Unique
                    $selectedCollectors = $selectedCollectors -replace '"', ""
                    return $selectedCollectors
                }
            }
        }
        Catch{
            Write-Error $_
        }
    }
}
