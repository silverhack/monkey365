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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, HelpMessage="Path to search")]
        [String]$Path,

        [Parameter(Mandatory=$false, HelpMessage="pattern")]
        [String[]]$Pattern,

        [Parameter(Mandatory=$false, HelpMessage="First occurrence")]
        [Switch]$First,

        [Parameter(Mandatory=$false, HelpMessage="Recursive search")]
        [Switch]$Recurse
    )
    If([System.IO.Directory]::Exists($PSBoundParameters['Path'])){
        If($PSBoundParameters.ContainsKey('Recurse') -and $PSBoundParameters['Recurse'].IsPresent){
            Try{
                $_list = [System.IO.Directory]::EnumerateDirectories($PSBoundParameters['Path'],"*",[System.IO.SearchOption]::AllDirectories)
                If($PSBoundParameters.ContainsKey('Pattern') -and $PSBoundParameters['Pattern']){
                    $_patternList = [System.Collections.Generic.List[System.String]]::new()
                    Foreach($patt in $Pattern){
                        If($PSBoundParameters.ContainsKey('First') -and $PSBoundParameters['First'].IsPresent){
                            $directory = $_list.Where({$_ -match $patt},[System.Management.Automation.WhereOperatorSelectionMode]::First);
                            Foreach($dir in $directory){
                                [void]$_patternList.Add($dir);
                            }
                        }
                        Else{
                            $directory = $_list.Where({$_ -match $patt});
                            Foreach($dir in $directory){
                                [void]$_patternList.Add($dir);
                            }
                        }
                    }
                    Write-Output $_patternList -NoEnumerate
                }
                Else{
                    If($PSBoundParameters.ContainsKey('First') -and $PSBoundParameters['First'].IsPresent){
                        $_list | Select-Object -First 1
                    }
                    Else{
                        Write-Output $_list -NoEnumerate
                    }
                }
            }
            Catch{
                Write-Error $_.Exception
            }
        }
        Else{
            $_list = [System.IO.Directory]::EnumerateDirectories($PSBoundParameters['Path'],"*",[System.IO.SearchOption]::TopDirectoryOnly)
            If($PSBoundParameters.ContainsKey('Pattern') -and $PSBoundParameters['Pattern']){
                $_patternList = [System.Collections.Generic.List[System.String]]::new()
                Foreach($patt in $Pattern){
                    If($PSBoundParameters.ContainsKey('First') -and $PSBoundParameters['First'].IsPresent){
                        $directory = $_list.Where({$_ -match $patt},[System.Management.Automation.WhereOperatorSelectionMode]::First);
                        Foreach($dir in $directory){
                            [void]$_patternList.Add($dir);
                        }
                    }
                    Else{
                        $directory = $_list.Where({$_ -match $patt});
                        Foreach($dir in $directory){
                            [void]$_patternList.Add($dir);
                        }
                    }
                }
                Write-Output $_patternList -NoEnumerate
            }
            Else{
                [System.IO.Directory]::EnumerateDirectories($PSBoundParameters['Path'],"*",[System.IO.SearchOption]::TopDirectoryOnly)
            }
        }
    }
    Else{
        Write-Warning ("Directory {0} was not found" -f $PSBoundParameters['Path'])
    }
}