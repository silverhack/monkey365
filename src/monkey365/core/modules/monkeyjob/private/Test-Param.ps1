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

Function Test-Param{
    <#
        .SYNOPSIS
        Check if ScriptBlock content contains a Param()

        .DESCRIPTION
        Check if ScriptBlock content contains a Param()

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-ScriptBlockParam
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$true, HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock
    )
    Begin{
        $query ='$args[0] -is [System.Management.Automation.Language.ParamBlockAst]'
    }
    Process{
        Try{
            If($ScriptBlock.Ast.ParamBlock){
                return $True
            }
            Else{
                #Get Command Info
                $commandInfo = Get-CommandInfo @PSBoundParameters
                If($null -eq $commandInfo){
                    #No information provided by commandInfo
                    #Try to get if a ParamBlockAst is set
                    $ci = Find-ElementFromAst @PSBoundParameters -Query $query -FindAll
                    If($null -ne $ci){
                        return $True
                    }
                    Else{
                        return $false
                    }
                }
                ElseIf($commandInfo.CommandType -eq "Cmdlet"){
                    return $false
                }
                Else{
                    #Search at commandInfo level
                    $ci = Find-ElementFromAst $commandInfo.ScriptBlock -Query $query -FindAll
                    If($null -ne $ci){
                        return $True
                    }
                    Else{
                        return $false
                    }
                }
            }
        }
        Catch{
            Write-Error $_
            return $false
        }
    }
}
