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

Function ConvertFrom-PsExpression {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertFrom-PsExpression
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="Object")]
        [Object]$InputObject,

        [Parameter(Mandatory=$true, HelpMessage="Extend object")]
        [System.Collections.Generic.List`1[System.Object]]$Expressions,

        [Parameter(Mandatory=$false, HelpMessage="Extend object")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$Expand
    )
    Set-StrictMode -Off
    if($PSBoundParameters.ContainsKey('Expand') -and $PSBoundParameters['Expand']){
        foreach($elem in @($InputObject)){
            if($PSBoundParameters.ContainsKey('Expand') -and $PSBoundParameters['Expand']){
                $subelements = $elem | Select-Object -ExpandProperty $PSBoundParameters['Expand'] -ErrorAction Ignore
                if($null -ne $subelements){
                    $subelements | Select-Object $Expressions -ErrorAction SilentlyContinue
                }
            }
            else{
                $elem | Select-Object $Expressions -ErrorAction SilentlyContinue
            }
        }
    }
    else{
        foreach($newItem in @($InputObject)){
            $newItem | Select-Object $Expressions -ErrorAction SilentlyContinue
        }
    }
}

