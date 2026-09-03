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

Function Get-ScriptBlock{
    <#
        .SYNOPSIS
        Check whether ScriptBlock is coming from CmdLet, external file, etc. Get a new ScriptBlock

        .DESCRIPTION
        Check whether ScriptBlock is coming from CmdLet, external file, etc. Get a new ScriptBlock

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ScriptBlock
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Management.Automation.ScriptBlock])]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$true, HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock
    )
    Process{
        Try{
            If($ScriptBlock.Ast.ParamBlock){
                return $ScriptBlock
            }
            Else{
                $commandInfo = Get-CommandInfo @PSBoundParameters
                If($null -ne $commandInfo -and $commandInfo.CommandType -eq [System.Management.Automation.CommandTypes]::ExternalScript){
                    If($commandInfo.ScriptBlock.Ast.ParamBlock){
                        $commandInfo.ScriptBlock
                    }
                    Else{
                        #Find FunctionDefinitionAst if any
                        $query ='$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]'
                        $ci = Find-ElementFromAst -ScriptBlock $commandInfo.ScriptBlock -Query $query -FindAll
                        If($null -ne $ci.Body.ParamBlock){
                            $ci.Body.GetScriptBlock()
                        }
                        Else{
                            return $ScriptBlock
                        }
                    }
                }
                Else{
                    #Find FunctionDefinitionAst if any
                    $query ='$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]'
                    $ci = Find-ElementFromAst @PSBoundParameters -Query $query -FindAll
                    If($null -ne $ci -and $null -ne $ci.Body.ParamBlock){
                        $ci.Body.GetScriptBlock()
                    }
                    Else{
                        return $ScriptBlock
                    }
                }
            }
        }
        Catch{
            Write-Error $_.Exception
        }
    }
}
