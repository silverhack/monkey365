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

Function Get-AstFunctionsFromFile{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AstFunctionsFromFile
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Array of files")]
        [Object]$Files
    )
    Begin{
        $all_functions = @()
        $tokens = $errors = $null
    }
    Process{
        foreach($fnc in $Files){
            if($fnc -is [System.Management.Automation.PSObject] -and $null -ne $fnc.Psobject.Properties.Item('FullName')){
                #Convert to filesystemInfo
                $fnc = [System.IO.fileinfo]::new($fnc)
            }
            elseif($fnc -is [System.String]){
                #Convert to filesystemInfo
                $fnc = [System.IO.fileinfo]::new($fnc)
            }
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $fnc.FullName,
                [ref]$tokens,
                [ref]$errors
            )
            # Get only function definition ASTs
            $all_functions += $ast.FindAll({
                param([System.Management.Automation.Language.Ast] $Ast)

                $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                ($PSVersionTable.PSVersion.Major -lt 5 -or
                $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

            }, $true)
        }
    }
    End{
        if($all_functions){
            return $all_functions
        }
        else{
            return $null
        }
    }
}
