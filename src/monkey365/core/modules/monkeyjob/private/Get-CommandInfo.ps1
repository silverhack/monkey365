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

Function Get-CommandInfo{
    <#
        .SYNOPSIS
        Get command information from ScriptBlock

        .DESCRIPTION
        Get command information from ScriptBlock

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-CommandInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([System.String], ParameterSetName='CommandName')]
    [OutputType([System.Management.Automation.CommandInfo], ParameterSetName='Default')]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$true, HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$false, HelpMessage = 'Get all commands')]
        [Switch]$All,

        [Parameter(Mandatory=$false, ParameterSetName='CommandName', HelpMessage = 'Get only command name')]
        [Switch]$Name
    )
    Begin{
        $query = '$Ast -is [System.Management.Automation.Language.CommandAst]'
    }
    Process{
        Try{
            #Set parameters
            $p = @{
                ScriptBlock = $ScriptBlock;
                Query = $query;
                AddParam = $True;
            }
            If($PSBoundParameters.ContainsKey('All') -and $PSBoundParameters['All'].IsPresent){
                [void]$p.Add('FindAll',$True)
            }
            #Get potential commands
            $commandElements = Find-ElementFromAst @p | Select-Object -ExpandProperty CommandElements -ErrorAction Ignore
            $allCommands = @($commandElements).Where({$null -ne $_ -and $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $_.StringConstantType -eq [System.Management.Automation.Language.StringConstantType]::BareWord})
            #Return only command name
            If($PSCmdlet.ParameterSetName.ToLower() -eq "commandname"){
                $allCommands | Select-Object -ExpandProperty value -ErrorAction Ignore
            }
            Else{#Return command Info
                $allCommands.ForEach({Get-Command -Name $_.value -ErrorAction Ignore})
            }
        }
        Catch{
            Write-Error $_
            return $null
        }
    }
}
