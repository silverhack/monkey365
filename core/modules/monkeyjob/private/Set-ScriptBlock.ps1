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

Function Set-ScriptBlock{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Set-ScriptBlock
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$True,position=0,ParameterSetName='ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$false,position=1,ValueFromPipeline=$true,ParameterSetName='ScriptBlock')]
        [Switch]$AddInputObject
    )
    Begin{
        $Params = New-Object System.Collections.ArrayList
        if($AddInputObject.IsPresent){
            [void]$Params.Add('$_')
        }
        $NewParameters = $Params -join ', '
        $commandInfo = Get-CommandInfo -ScriptBlock $ScriptBlock
        if($null -ne $commandInfo -and $commandInfo.CommandType -eq 'ExternalScript'){
            #External script detected. Create new scriptblock
            $ScriptBlock = Get-NewScriptBlock -CommandInfo $commandInfo
        }
    }
    Process{
        if($null -eq $ScriptBlock.Ast.ParamBlock){
            $StringScriptBlock = "Param($($NewParameters))`n$($ScriptBlock.ToString())"
            $ScriptBlock = [scriptblock]::Create($StringScriptBlock)
        }
    }
    End{
        $ScriptBlock
    }
}

