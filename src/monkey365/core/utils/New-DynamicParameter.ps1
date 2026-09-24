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
    param(
        [Parameter(Mandatory = $true, HelpMessage= "Name")]
        [string] $Name,

        [Parameter(Mandatory = $true, HelpMessage= "Type")]
        [type] $Type,

        [Parameter(Mandatory = $false, HelpMessage= "Alias")]
        [string[]] $Alias,

        [Parameter(Mandatory = $false, HelpMessage= "Validate")]
        [string[]] $ValidateSet,

        [Parameter(Mandatory = $false, HelpMessage= "Validate Script")]
        [scriptblock] $ValidateScript
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