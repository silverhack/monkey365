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

Function Get-FindingLegend {
    <#
        .SYNOPSIS
		Get legend for a finding object

        .DESCRIPTION
		Get legend for a finding object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-FindingLegend
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
    [OutputType([System.String])]
	Param (
        [parameter(Mandatory=$false, HelpMessage="MonkeyObject")]
        [Object]$InputObject,

        [parameter(Mandatory=$true, HelpMessage="Status Object")]
        [Object]$StatusObject
    )
    #Create a dictionary
    $dict = @{}
    If($PSBoundParameters.ContainsKey('InputObject') -and $PSBoundParameters['InputObject']){
        Foreach($key in @($StatusObject.keyName).GetEnumerator()){
            If($dict.ContainsKey($key)){continue}
            $dict.Add($key,$InputObject.GetPropertyByPath($key))
        }
    }
    #match/replace
    $statusMsg = $StatusObject.message
    foreach($elem in $dict.GetEnumerator()){
        $a = $elem.Name
        $m = ("\{$a\}")
        $statusMsg = $statusMsg -replace $m, $elem.Value
    }
    return $statusMsg
}

