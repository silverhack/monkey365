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

Function Get-MonkeyJobAstFunction{
    <#
        .SYNOPSIS
        Get Abstract Syntax Tree functions

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyJobAstFunction
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.Language.FunctionDefinitionAst]])]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Objects")]
        [Object[]]$Objects,

        [Parameter(Mandatory=$false, HelpMessage="Recursive Search")]
        [Switch]$recursive
    )
    Begin{
        $all_functions = [System.Collections.Generic.List[System.Management.Automation.Language.FunctionDefinitionAst]]::new()
        $tokens = $errors = $null
    }
    Process{
        foreach($object in $Objects){
            $ast = $null
            If($object -is [string]){
                #Check if file
                if([System.IO.File]::Exists($object)){
                    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                        $object,
                        [ref]$tokens,
                        [ref]$errors
                    )
                }
                else{
                    #Probably Powershell command
                    $local_function = Get-Content Function:\$object -ErrorAction Ignore
                    if($null -ne $local_function){
                        $ast = $local_function.Ast
                    }
                }
            }
            Elseif($object -is [System.IO.FileSystemInfo]){
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $object.FullName,
                    [ref]$tokens,
                    [ref]$errors
                )
            }
            Elseif($object -is [System.Management.Automation.PSObject] -and $null -ne $object.Psobject.Properties.Item('FullName')){
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $object.FullName,
                    [ref]$tokens,
                    [ref]$errors
                )
            }
            elseif($object -is [scriptblock]){
                $ast = $object.Ast
            }
            Else{
                Write-Verbose "Unable to determine file"
            }
            if($null -ne $ast -and $recursive){
                # Get only function definition ASTs
                $all_fncs = $ast.FindAll({
                    param([System.Management.Automation.Language.Ast] $Ast)

                    $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                    ($PSVersionTable.PSVersion.Major -lt 5 -or
                    $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

                }, $true)
                if($all_fncs){
                    foreach($fnc in @($all_fncs)){
                        [void]$all_functions.Add($fnc)
                    }
                }
            }
            else{
                # Get only first function definition ASTs
                $all_fncs = $ast.Find({
                        param([System.Management.Automation.Language.Ast] $Ast)

                        $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                        # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                        ($PSVersionTable.PSVersion.Major -lt 5 -or
                        $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

                    }, $true)
                if($all_fncs){
                    foreach($fnc in @($all_fncs)){
                        [void]$all_functions.Add($fnc)
                    }
                }
            }
        }
    }
    End{
        $all_functions
    }
}