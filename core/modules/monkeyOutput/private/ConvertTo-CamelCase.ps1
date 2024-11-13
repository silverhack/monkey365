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

Function ConvertTo-CamelCase {
    <#
        .SYNOPSIS
		Convert string to camelcase

        .DESCRIPTION
		Convert string to camelcase

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-CamelCase
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
    [OutputType([System.String])]
	Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="String")]
        [String]$InputObject
    )
    Process{
        $myStr = [regex]::Replace(
            $InputObject,
            '[-_](\p{L})',
            { $args[0].Groups[1].Value.ToUpper() }
        )
        $camelCaseStr = $myStr[0].ToString().ToLower(), $myStr.TrimStart($myStr[0]) -join ''
        return $camelCaseStr
    }
}