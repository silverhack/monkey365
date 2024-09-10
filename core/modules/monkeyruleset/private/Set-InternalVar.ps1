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


Function Set-InternalVar{
    <#
        .SYNOPSIS
		Initialize ruleset vars. Check if rules and conditions folder exists

        .DESCRIPTION
        Initialize ruleset vars. Check if rules and conditions folder exists

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Set-InternalVar
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Rules Path")]
        [String]$InputObject
    )
    Process{
        $findingsPath = $conditionsPath = $rulesetsPath = $null
        Try{
            $initPath = [System.IO.DirectoryInfo]::new($InputObject);
            If($null -ne $initPath.GetDirectories('findings')){
                Write-Verbose -Message ($Script:messages.DirectoryFoundMessage -f "findings", $initPath.FullName)
                $findingsPath = $initPath.GetDirectories('findings')
            }
            If($null -ne $initPath.GetDirectories('conditions')){
                Write-Verbose -Message ($Script:messages.DirectoryFoundMessage -f "conditions", $initPath.FullName)
                $conditionsPath = $initPath.GetDirectories('conditions')
            }
            If($null -ne $initPath.GetDirectories('rulesets')){
                Write-Verbose -Message ($Script:messages.DirectoryFoundMessage -f "rulesets", $initPath.FullName)
                $rulesetsPath = $initPath.GetDirectories('rulesets')
            }
            If($null -ne $findingsPath -and $null -ne $conditionsPath -and $null -ne $rulesetsPath){
                New-Variable -Name FindingsPath -Value $findingsPath.FullName.ToString() -Scope Script -Force
                New-Variable -Name ConditionsPath -Value $conditionsPath.FullName.ToString() -Scope Script -Force
                New-Variable -Name RulesetsPath -Value $rulesetsPath.FullName.ToString() -Scope Script -Force
            }
            Else{
                Write-Warning $Script:messages.UnableToInitializeVars
            }
        }
        Catch{
            Write-Warning $Script:messages.UnableToInitializeVars
            Write-Verbose $_.Exception.Message
        }
    }
}
