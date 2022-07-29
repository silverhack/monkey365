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

Function Get-CommandToExecute{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-CommandToExecute
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Management.Automation.Language.StringConstantExpressionAst])]
    Param (
            [Parameter(Mandatory=$True,ParameterSetName='ScriptBlock')]
            [System.Management.Automation.ScriptBlock]$ScriptBlock,

            [Parameter(Mandatory=$false)]
            [Switch]$First
    )
    try{
        $query = '$Ast -is [System.Management.Automation.Language.CommandAst]'
        $CommandAsts = Get-ElementFromAst -ScriptBlock $ScriptBlock -Query $query
        #$CommandAsts = $scriptblock.Ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]} , $true)
        if($First){
            #Get first command to process
            $CommandToProcess = $CommandAsts.CommandElements | Select-Object -First 1
        }
        else{
            $CommandToProcess = $CommandAsts.CommandElements
        }
        return $CommandToProcess
    }
    catch{
        Write-Information $_ -Tags @('CommandToProcessError')
        return $null
    }
}
