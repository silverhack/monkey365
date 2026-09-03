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

Function Find-ElementFromAst{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ElementFromAst
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$True,HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$True, HelpMessage = 'AST Query')]
        [String]$Query,

        [Parameter(Mandatory=$false, HelpMessage = 'Add Param scriptblock')]
        [Switch]$AddParam,

        [Parameter(Mandatory=$false, HelpMessage = 'Search nested functions')]
        [Switch]$Nested,

        [Parameter(Mandatory=$false, HelpMessage = 'Traverse the entire AST and return all nodes')]
        [Switch]$FindAll
    )
    Begin{
        #Set null
        $sbQuery = $null
        Try{
            #Check if AddParam is present
            If($AddParam.IsPresent){
                $txt_query = ('param([System.Management.Automation.Language.Ast] $Ast); {0}' -f $Query)
                $tokens = $errors = $null
                $parseInputQuery = [System.Management.Automation.Language.Parser]::ParseInput($txt_query, [ref]$tokens, [ref]$errors)
                $sbQuery = $parseInputQuery.GetScriptBlock()
            }
            Else{
                $sbQuery = [System.Management.Automation.ScriptBlock]::Create($Query)
            }
        }
        Catch{
            Write-Error $_.Exception
        }
    }
    Process{
        Try{
            If($null -ne $sbQuery){
                If($FindAll.IsPresent){
                    $ScriptBlock.Ast.FindAll($sbQuery, $Nested.IsPresent)
                }
                Else{
                    $ScriptBlock.Ast.Find($sbQuery, $Nested.IsPresent)
                }
            }
        }
        Catch{
            Write-Error $_.Exception
        }
    }
    End{
        #Nothing to do here
    }
}
