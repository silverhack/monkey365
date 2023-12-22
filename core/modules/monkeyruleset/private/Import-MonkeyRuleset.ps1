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

Function Import-MonkeyRuleset{
    <#
        .SYNOPSIS
		Get rules from ruleset file. If file is valid, then create an script variable

        .DESCRIPTION
		Get rules from ruleset file. If file is valid, then create an script variable

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Import-MonkeyRuleset
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ParameterSetName = 'RuleSetObject',HelpMessage="Ruleset File")]
        [Object]$RulesetObject,

        [parameter(Mandatory=$True, ParameterSetName = 'RuleSet',HelpMessage="Ruleset File")]
        [String]$Ruleset
    )
    try{
        if($PSCmdlet.ParameterSetName -eq 'RuleSet'){
            $p = @{
                Ruleset = $Ruleset;
            }
            $myRuleSet = Get-MonkeyRuleSet @p
            if($myRuleSet){
                New-Variable -Name SecBaseline -Value $myRuleSet -Scope Script -Force
            }
        }
        else{
            if(Test-isValidRuleSet -Object $RulesetObject){
                New-Variable -Name SecBaseline -Value $RulesetObject -Scope Script -Force
            }
        }
    }
    catch{
        Write-Warning $Script:messages.UnableToSetRuleset
        Write-Verbose $_.Exception.Message
    }
}