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

            [Parameter(Mandatory=$false)]
            [String]$Query,

            [Parameter(Mandatory=$false)]
            [Switch]$Detailed
    )
    Begin{
        $all_elements = @()
        if($Query){
            #$my_query = [ScriptBlock]::Create(('param([System.Management.Automation.Language.Ast] $Ast); {0}' -f $Query))
            #$matchedElements = $ScriptBlock.Ast.FindAll($my_query, $true) | Where-Object { $_ }
            $txt_query = ('param([System.Management.Automation.Language.Ast] $Ast); {0}' -f $Query)
            $my_query = [System.Management.Automation.Language.Parser]::ParseInput($txt_query, [ref]$null, [ref]$null)
            $matchedElements = $ScriptBlock.Ast.FindAll($my_query.GetScriptBlock(), $true) | Where-Object { $_ }
        }
        else{
            $matchedElements = $null
        }
    }
    Process{
        if ($null -ne $matchedElements) {
            if($Detailed){
                foreach ($element in $matchedElements) {
                    [pscustomobject]$match = @{
                        Text = $element.Extent.Text;
                        Line = $element.Extent.StartLineNumber;
                        Position = $element.Extent.StartColumnNumber
                        ParentText = $element.Parent.Extent.Text
                        rawElement = $element
                    }
                    $all_elements+=$match
                }
            }
            else{
                $all_elements = $matchedElements
            }
        }
    }
    End{
        if($all_elements){
            return $all_elements
        }
        else{
            return $null
        }
    }
}
