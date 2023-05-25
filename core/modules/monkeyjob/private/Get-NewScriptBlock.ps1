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

Function Get-NewScriptBlock{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-NewScriptBlock
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Management.Automation.ScriptBlock])]
    Param (
            [Parameter(Mandatory=$True,position=0,ParameterSetName='CommandInfo')]
            [System.Management.Automation.CommandInfo]$CommandInfo
    )
    try{
        $MetaData = [System.Management.Automation.CommandMetadata]::New($CommandInfo)
        #$CmdletBinding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($Metadata)
        $Paramblock = [System.Management.Automation.ProxyCommand]::GetParamBlock($Metadata)
        if([string]::IsNullOrEmpty($Paramblock)){
            Write-Information ("{0} does not use any parameters. Trying to find function within scriptblock" -f $commandInfo.Name)
            $PathExists = Test-Path -Path $CommandInfo.Source -PathType Leaf
            if($PathExists){
                $tokens = $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $CommandInfo.Source,
                    [ref]$tokens,
                    [ref]$errors
                )
                $fnc = $ast.Find({
                            param([System.Management.Automation.Language.Ast] $Ast)

                            $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                            # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                            ($PSVersionTable.PSVersion.Major -lt 5 -or
                            $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

                        }, $true)
                if($fnc){
                    $PScript = $fnc.Body.GetScriptBlock()
                }
            }
        }
        else{
            #Remove the body of the actual function and replace it with the custom code to return the Parameters used.
            $PScript = [System.Management.Automation.ProxyCommand]::Create($MetaData)
		    #$PScript = [scriptblock]::Create($PScript)
            $parsed = [System.Management.Automation.Language.Parser]::ParseInput($PScript, [ref]$null, [ref]$null)
            if($null -ne $parsed){
                $PScript = $parsed.GetScriptBlock()
            }
        }
        return $PScript
    }
    catch{
        Write-Error $_
    }
}