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

Function Get-MonkeyDirectory{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyDirectory
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, HelpMessage="Path to search")]
        [String]$Path,

        [Parameter(Mandatory=$false, HelpMessage="recursion")]
        [Int32]$Level,

        [Parameter(Mandatory=$false, HelpMessage="pattern")]
        [String]$Pattern
    )
    $_list = [System.Collections.Generic.List[System.String]]::new()
    Foreach($_path in [System.IO.Directory]::EnumerateDirectories($PSBoundParameters['Path'],"*",[System.IO.SearchOption]::TopDirectoryOnly)){
        [void]$_list.Add($_path)
        if($PSBoundParameters.ContainsKey('level') -and $PSBoundParameters['level'] -gt 0){
            try{
                $dirs = (Get-MonkeyDirectory -Path $_path -Level ($PSBoundParameters['level'] - 1))
                if($dirs){
                    [void]$_list.AddRange($dirs)
                }
            }
            catch{
                Write-Warning $_
            }
        }
    }
    Write-Output $_list -NoEnumerate
}