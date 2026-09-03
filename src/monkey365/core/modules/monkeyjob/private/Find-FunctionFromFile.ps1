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

Function Find-FunctionFromFile{
    <#
        .SYNOPSIS
        Utility to search for FunctionDefinitionAst elements from files

        .DESCRIPTION
        Utility to search for FunctionDefinitionAst elements from files

        .INPUTS
        Files

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Find-FunctionFromFile
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$true, HelpMessage = 'Files')]
        [Object]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage = 'Search nested functions')]
        [Switch]$Nested,

        [Parameter(Mandatory=$false, HelpMessage = 'Traverse the entire AST and return all nodes')]
        [Switch]$FindAll
    )
    Begin{
        #Set null
        $tokens = $errors = $sbQuery = $null
        Try{
            #Set Query
            $txt_query = 'param([System.Management.Automation.Language.Ast] $Ast); $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and ($PSVersionTable.PSVersion.Major -lt 5 -or $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])'
            #Parse Input query
            $parseInputQuery = [System.Management.Automation.Language.Parser]::ParseInput($txt_query, [ref]$tokens, [ref]$errors)
            #Create query
            $sbQuery = $parseInputQuery.GetScriptBlock();
        }
        Catch{
            Write-Error $_
        }
    }
    Process{
        Try{
            If($null -ne $sbQuery){
                ForEach($_object in @($InputObject)){
                    If([System.IO.File]::Exists($_object)){
                        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                            $_object,
                            [ref]$tokens,
                            [ref]$errors
                        )
                        #Find elements
                        If($FindAll.IsPresent){
                            $ast.FindAll($sbQuery, $Nested.IsPresent);
                        }
                        Else{
                            $ast.Find($sbQuery, $Nested.IsPresent);
                        }
                    }
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
