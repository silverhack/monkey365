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

Function Get-CastValue{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-CastValue
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Element to check")]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$InputObject
    )
    Process{
        $Value = $null;
        If([string]::IsNullOrEmpty($InputObject)){
            $Value = "$null";
        }
        ElseIf($InputObject -is [System.String]){
            $Value = ("'{0}'" -f [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($InputObject))
        }
        ElseIf($InputObject -is [Boolean]){
            $Value = ('{0}' -f $InputObject)
        }
        ElseIf ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]){
            $Value = ('@({0})' -f ('"' + ($InputObject -join '","')+ '"'))
        }
        return $Value
    }
}


