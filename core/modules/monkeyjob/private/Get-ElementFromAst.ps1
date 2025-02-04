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

Function Get-ElementFromAst{
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
            [Parameter(Mandatory=$True,ParameterSetName='ScriptBlock')]
            [System.Management.Automation.ScriptBlock]$ScriptBlock,

            [Parameter(Mandatory=$True)]
            [String]$Query
    )
    Begin{
        $txt_query = ('param([System.Management.Automation.Language.Ast] $Ast); {0}' -f $Query)
    }
    Process{
        $my_query = [System.Management.Automation.Language.Parser]::ParseInput($txt_query, [ref]$null, [ref]$null)
        $matchedElements = $ScriptBlock.Ast.FindAll($my_query.GetScriptBlock(), $true) | Where-Object { $_ }
    }
    End{
        $matchedElements
    }
}

