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

function Get-ComparisonOperator{
    <#
        .SYNOPSIS
        Returns a scriptblock object that represents the compiled query

        .DESCRIPTION
        Returns a scriptblock object that represents the compiled query

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ComparisonOperator
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ScriptBlock])]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Conditions")]
        [Object]$InputObject
    )
    Process{
        Try{
            [array]$comparison_operators = [Linq.Enumerable]::Where(
                [Linq.Enumerable]::Range(0, $InputObject.Length),
                [Func[int, bool]] { param($i)
                    $InputObject[$i] -eq 'eq' `
                    -or $InputObject[$i] -eq 'ieq' `
                    -or $InputObject[$i] -eq 'ceq' `
                    -or $InputObject[$i] -eq 'ne' `
                    -or $InputObject[$i] -eq 'ine' `
                    -or $InputObject[$i] -eq 'cne' `
                    -or $InputObject[$i] -eq 'gt' `
                    -or $InputObject[$i] -eq 'igt' `
                    -or $InputObject[$i] -eq 'cgt' `
                    -or $InputObject[$i] -eq 'ge' `
                    -or $InputObject[$i] -eq 'ige' `
                    -or $InputObject[$i] -eq 'cge' `
                    -or $InputObject[$i] -eq 'lt' `
                    -or $InputObject[$i] -eq 'ilt' `
                    -or $InputObject[$i] -eq 'clt' `
                    -or $InputObject[$i] -eq 'le' `
                    -or $InputObject[$i] -eq 'ile' `
                    -or $InputObject[$i] -eq 'cle' `
                    -or $InputObject[$i] -eq 'like' `
                    -or $InputObject[$i] -eq 'ilike' `
                    -or $InputObject[$i] -eq 'clike' `
                    -or $InputObject[$i] -eq 'notlike' `
                    -or $InputObject[$i] -eq 'inotlike' `
                    -or $InputObject[$i] -eq 'cnotlike' `
                    -or $InputObject[$i] -eq 'match' `
                    -or $InputObject[$i] -eq 'imatch' `
                    -or $InputObject[$i] -eq 'cmatch' `
                    -or $InputObject[$i] -eq 'notmatch' `
                    -or $InputObject[$i] -eq 'inotmatch' `
                    -or $InputObject[$i] -eq 'cnotmatch' `
                    -or $InputObject[$i] -eq 'replace' `
                    -or $InputObject[$i] -eq 'ireplace' `
                    -or $InputObject[$i] -eq 'creplace' `
                    -or $InputObject[$i] -eq 'contains' `
                    -or $InputObject[$i] -eq 'icontains' `
                    -or $InputObject[$i] -eq 'ccontains' `
                    -or $InputObject[$i] -eq 'notcontains' `
                    -or $InputObject[$i] -eq 'inotcontains' `
                    -or $InputObject[$i] -eq 'cnotcontains' `
                    -or $InputObject[$i] -eq 'in' `
                    -or $InputObject[$i] -eq 'notin' `
                    -or $InputObject[$i] -eq 'is' `
                    -or $InputObject[$i] -eq 'isnot' `
                }
            )
            return $comparison_operators
        }
        Catch{
            Write-Error $_
        }
    }
}