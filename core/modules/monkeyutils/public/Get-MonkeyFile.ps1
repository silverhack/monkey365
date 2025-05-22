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

Function Get-MonkeyFile{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyFile
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Path to search")]
        [String]$Path,

        [Parameter(Mandatory=$false, HelpMessage="pattern")]
        [String]$Pattern = "*ps1",

        [Parameter(Mandatory=$false, HelpMessage="Recursive search")]
        [Switch]$Recurse
    )
    Process{
        if($PSBoundParameters.ContainsKey('Recurse') -and $PSBoundParameters['Recurse'].isPresent){
            $options = [System.IO.SearchOption]::AllDirectories
        }
        else{
            $options = [System.IO.SearchOption]::TopDirectoryOnly
        }
        if ([System.IO.Directory]::Exists($Path)){
            [System.IO.Directory]::EnumerateFiles($Path,$Pattern,$options)
        }
    }
}
