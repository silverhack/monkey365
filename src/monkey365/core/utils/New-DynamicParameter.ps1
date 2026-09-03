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

Function New-DynamicParameter {
    <#
        .SYNOPSIS
        Create a new dynamic parameter for a PowerShell function.
        .DESCRIPTION
        This function allows you to create a new dynamic parameter that can be added to a PowerShell function at runtime.
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-DynamicParameter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, HelpMessage= "Name")]
        [System.String] $Name,

        [Parameter(Mandatory = $true, HelpMessage= "Type")]
        [System.Type] $Type,

        [Parameter(Mandatory = $false, HelpMessage= "Alias")]
        [System.String[]] $Alias,

        [Parameter(Mandatory = $false, HelpMessage= "Validate")]
        [System.String[]] $ValidateSet,

        [Parameter(Mandatory = $false, HelpMessage= "Validate Script")]
        [System.Management.Automation.ScriptBlock] $ValidateScript
    )

    $attributes = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

    $paramAttr = [System.Management.Automation.ParameterAttribute]::new()
    $paramAttr.Mandatory = $false
    $attributes.Add($paramAttr)

    If ($Alias) {
        $attributes.Add([System.Management.Automation.AliasAttribute]::new($Alias))
    }

    If ($ValidateSet) {
        $attributes.Add([System.Management.Automation.ValidateSetAttribute]::new([string[]]$ValidateSet))
    }

    If ($ValidateScript) {
        $attributes.Add([System.Management.Automation.ValidateScriptAttribute]::new($ValidateScript))
    }

    [System.Management.Automation.RuntimeDefinedParameter]::new(
        $Name,
        $Type,
        $attributes
    )
}