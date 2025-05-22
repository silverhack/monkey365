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

Function Format-Json {
    <#
        .SYNOPSIS
		Prettier formatting for JSON object

        .DESCRIPTION
		Prettier formatting for JSON object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Format-Json
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
	[CmdletBinding()]
    [OutputType([System.String])]
	Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="JSON object")]
        [String]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage="Indentation. Default 2")]
        [ValidateRange(1, 1024)]
        [int]$Indentation = 2
    )
    Process{
        $indent = 0;
        ($InputObject -Split [System.Environment]::NewLine).ForEach(
            {
                if ($_ -match '[\}\]]') {
                    # If line contains ] or }, decrement the indentation level
                    $indent = [Math]::Max($indent - $Indentation, 0)
                }
                $line = (' ' * $indent) + $_.TrimStart().Replace(':  ', ': ')
                if ($_ -match '[\{\[]') {
                    # If line contains [ or {, increment the indentation level
                    $indent += $Indentation
                }
                $line
            }
        ) -Join [System.Environment]::NewLine
    }
}
