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

Function Get-Ruleset{
    <#
        .SYNOPSIS
		Get rule

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-Ruleset
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Basic information")]
        [Switch]$Info,

        [parameter(Mandatory=$false, HelpMessage="About")]
        [Switch]$About,

        [parameter(Mandatory=$false, HelpMessage="Framework")]
        [Switch]$Framework
    )
    try{
        if($null -ne (Get-Variable -Name SecBaseline -ErrorAction Ignore)){
            if($PSBoundParameters.ContainsKey('Info') -and $PSBoundParameters['Info']){
                $fname = $Script:SecBaseline.framework | Select-Object -ExpandProperty Name -ErrorAction Ignore
                $fversion = $Script:SecBaseline.framework | Select-Object -ExpandProperty version -ErrorAction Ignore
                $r_about = $Script:SecBaseline | Select-Object -ExpandProperty about -ErrorAction Ignore
                $rulesetInfo = [PsCustomObject]@{
                    about = $r_about;
                    name = ("{0} {1}" -f $fname,$fversion)
                }
                return $rulesetInfo
            }
            Elseif($PSBoundParameters.ContainsKey('About') -and $PSBoundParameters['About']){
                $Script:SecBaseline.about
            }
            Elseif($PSBoundParameters.ContainsKey('Framework') -and $PSBoundParameters['Framework']){
                try{
                    $fname = $Script:SecBaseline.framework | Select-Object -ExpandProperty Name -ErrorAction Ignore
                    $fversion = $Script:SecBaseline.framework | Select-Object -ExpandProperty version -ErrorAction Ignore
                    ("{0} {1}" -f $fname,$fversion)
                }
                catch{
                    Write-Error $_
                }
            }
            else{
                $Script:SecBaseline
            }
        }
    }
    catch{
        Write-Verbose $_.Exception.Message
    }
}


