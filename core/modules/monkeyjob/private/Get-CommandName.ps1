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

Function Get-CommandName{
    <#
        .SYNOPSIS
        Get Command name from ScriptBlock

        .DESCRIPTION
        Get Command name from ScriptBlock

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-CommandName
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$True,position=0, ValueFromPipeline=$true, HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock
    )
    Begin{
        $query = '$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]'
    }
    Process{
        #Get Command info
        $commandInfo = Get-CommandInfo @PSBoundParameters -All
        #Find Function Name
        $ci = Find-ElementFromAst @PSBoundParameters -Query $query -FindAll
        If($null -ne $ci -and $null -ne $ci.Name){
            return $ci.Name
        }
        ElseIf($null -ne $commandInfo){
            If($commandInfo.CommandType -eq [System.Management.Automation.CommandTypes]::ExternalScript){
                #Find Function Name
                $ci = Find-ElementFromAst -ScriptBlock $commandInfo.ScriptBlock -Query $query -FindAll
                If($null -ne $ci -and $null -ne $ci.Name){
                    return $ci.Name
                }
            }
            Else{
                Get-CommandInfo @PSBoundParameters -All -Name
            }
        }
        Else{
            Get-CommandInfo @PSBoundParameters -All -Name
        }
    }
}