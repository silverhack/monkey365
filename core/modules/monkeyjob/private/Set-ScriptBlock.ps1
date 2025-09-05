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
        Create a new ScriptBlock. Add Param() block with parameters if not exists

        .DESCRIPTION
        Create a new ScriptBlock. Add Param() block with parameters if not exists

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
    [OutputType([System.Management.Automation.ScriptBlock])]
    Param (
        [Parameter(Mandatory=$True,position=0,HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$false,position=1, HelpMessage = 'Add InputObject')]
        [Object]$InputObject,

        [Parameter(Mandatory=$false,position=2, HelpMessage = 'Append parameters if any')]
        [Object]$Arguments
    )
    #Set Null
    $_ScriptBlock = $null
    #Set array list
    $_parameters = [System.Collections.ArrayList]::new()
    #Set string builder. Used when ScriptBlock has only one calling function and no parameters
    $_additionalParameters = [System.Text.StringBuilder]::new()
    #Test if Scriptblock has a block Param
    If($ScriptBlock | Test-ScriptBlockParam){
        $ScriptBlock | Get-ScriptBlock
    }
    Else{
        #Get ScriptBlock
        $_ScriptBlock = $ScriptBlock | Get-ScriptBlock
        #Format parameters
        If($PSBoundParameters.ContainsKey('InputObject') -and $PSBoundParameters['InputObject']){
            [void]$_parameters.Add('$_')
            If(-NOT $ScriptBlock.ToString().Contains('$_')){
                [void]$_additionalParameters.Append('$_')
                [void]$_additionalParameters.Append(" ")
            }
        }
        #Check if additional arguments
        If($PSBoundParameters.ContainsKey('Arguments') -and $PSBoundParameters['Arguments']){
            #Check if dictionary
            If(([System.Collections.IDictionary]).IsAssignableFrom($PSBoundParameters['Arguments'].GetType())){
                ForEach($element in $PSBoundParameters['Arguments'].GetEnumerator()){
                    [void]$_parameters.Add(('${0}' -f $element.Name))
                    If(-NOT $ScriptBlock.ToString().Contains($element.Name)){
                        [void]$_additionalParameters.Append(('-{0} ${1}' -f $element.Name,$element.Name))
                        [void]$_additionalParameters.Append(" ")
                    }
                }
            }
            #Check if array
            ElseIf ($PSBoundParameters['Arguments'] -is [System.Collections.IEnumerable]){
                $count = 0
                ForEach($_argument in @($PSBoundParameters['Arguments'])){
                    $count = $count+=1
                    [void]$_parameters.Add(('$using{0}' -f $count))
                    [void]$_additionalParameters.Append(('$using{0}' -f $count))
                    [void]$_additionalParameters.Append(" ")
                }
            }
            Else{
                Write-Warning $Script:messages.UnableToGetAdditionalParam
            }
        }
        #Check if ScriptBlock is a custom function
        If(-NOT ($ScriptBlock | Test-IsCustomFunction)){
            #Check if a simple command is passed through ScripbBlock
            #Get parameters
            $_sbParams = $ScriptBlock | Get-ScriptBlockParam
            If($_sbParams.Count -eq 0 -and @($ScriptBlock | Get-CommandName).Count -eq 1){
                #Get Command name
                $cn = $ScriptBlock | Get-CommandName
                $newCommand = ("{0} {1}" -f $cn,$_additionalParameters.ToString());
                $NewParameters = $_parameters -join ', '
                $StringScriptBlock = "Param($($NewParameters))`n$($newCommand)"
                #return new scriptblock
                [System.Management.Automation.ScriptBlock]::Create($StringScriptBlock)

            }
            Else{
                $NewParameters = $_parameters -join ', '
                $newSb = ("{0} {1}" -f $ScriptBlock.ToString(), $_additionalParameters.ToString())
                $StringScriptBlock = "Param($($NewParameters))`n$($newSb.ToString())"
                #return new scriptblock
                [System.Management.Automation.ScriptBlock]::Create($StringScriptBlock)
            }
        }
        Else{
            Write-Verbose $Script:messages.CustomFunctionMessage
            $NewParameters = $_parameters -join ', '
            $StringScriptBlock = "Param($($NewParameters))`n$($_ScriptBlock.ToString())"
            #return new scriptblock
            [System.Management.Automation.ScriptBlock]::Create($StringScriptBlock)
        }
    }
}
