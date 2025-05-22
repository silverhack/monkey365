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


Function Remove-InternalVar{
    <#
        .SYNOPSIS
		Remove ruleset vars

        .DESCRIPTION
        Remove ruleset vars

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Remove-InternalVar
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("InjectionRisk.Create", "", Scope="Function")]
    [CmdletBinding()]
    Param ()
    try{
        if($null -ne (Get-Variable -Name FindingsPath -ErrorAction Ignore)){
            Remove-Variable -Name FindingsPath -Scope Script -Force -ErrorAction Ignore
        }
        if($null -ne (Get-Variable -Name ConditionsPath -ErrorAction Ignore)){
            Remove-Variable -Name ConditionsPath -Scope Script -Force -ErrorAction Ignore
        }
        if($null -ne (Get-Variable -Name RulesetsPath -ErrorAction Ignore)){
            Remove-Variable -Name RulesetsPath -Scope Script -Force -ErrorAction Ignore
        }
        if($null -ne (Get-Variable -Name SecBaseline -ErrorAction Ignore)){
            Remove-Variable -Name SecBaseline -Scope Script -Force -ErrorAction Ignore
        }
        if($null -ne (Get-Variable -Name AllRules -ErrorAction Ignore)){
            Remove-Variable -Name AllRules -Scope Script -Force -ErrorAction Ignore
        }
    }
    catch{
        Write-Warning $Script:messages.UnableToRemoveVars
        Write-Verbose $_.Exception.Message
    }
}

