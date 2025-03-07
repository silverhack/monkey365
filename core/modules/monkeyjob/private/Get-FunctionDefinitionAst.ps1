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

Function Get-FunctionDefinitionAst{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-FunctionDefinitionAst
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Array of files")]
        [Object]$objects,

        [Parameter(Mandatory=$false, HelpMessage="Recursive Search")]
        [Switch]$recursive
    )
    Begin{
        $tokens = $errors = $null
    }
    Process{
        foreach($object in $objects){
            if($object -isnot [System.IO.FileSystemInfo]){
                if($object -is [System.Management.Automation.PSObject] -and $null -ne $object.Psobject.Properties.Item('FullName')){
                    #Convert to filesystemInfo
                    $object = [System.IO.fileinfo]::new($object)
                }
                elseif($object -is [System.String]){
                    #Convert to filesystemInfo
                    $object = [System.IO.fileinfo]::new($object)
                }
            }
            if($object -is [System.IO.FileSystemInfo]){
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $object.FullName,
                    [ref]$tokens,
                    [ref]$errors
                )
                if($recursive){
                    # Get only function definition ASTs
                    $ast.FindAll({
                        param([System.Management.Automation.Language.Ast] $Ast)

                        $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                        # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                        ($PSVersionTable.PSVersion.Major -lt 5 -or
                        $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

                    }, $true)
                }
                else{
                    # Get only first function definition ASTs
                    $ast.Find({
                        param([System.Management.Automation.Language.Ast] $Ast)

                        $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                        # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                        ($PSVersionTable.PSVersion.Major -lt 5 -or
                        $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

                    }, $true)
                }
            }
            elseif($object -is [string]){
                $fnc = Get-Item Function:\$object -ErrorAction SilentlyContinue
                if($null -ne $fnc){
                    #Check if custom function from local script
                    if($fnc.ScriptBlock.File){
                        $local_function = Get-Content Function:\$object
                        $local_function.Ast
                    }
                }
            }
            elseif($object -is [scriptblock]){
                $object.Ast
            }
        }
    }
    End{
        #Nothing to do here
    }
}


