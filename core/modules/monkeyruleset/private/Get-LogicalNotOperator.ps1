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

function Get-LogicalNotOperator{
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
            File Name	: Get-LogicalNotOperator
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ScriptBlock])]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Operator")]
        [String]$InputObject
    )
    Process{
        Try{
            $obj = @($InputObject)
            [array]$logicalNot_operators = [Linq.Enumerable]::Where(
                [Linq.Enumerable]::Range(0, $obj.Length),
                [Func[int, bool]] { param($i)
                    $obj[$i] -eq 'not' -or $obj[$i] -eq '!'
                }
            )
            return $logicalNot_operators
        }
        Catch{
            Write-Error $_
        }
    }
}