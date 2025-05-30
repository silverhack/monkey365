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

Function Get-MonkeyRuleSet{
    <#
        .SYNOPSIS
		Get content from ruleset file.

        .DESCRIPTION
		Get content from ruleset file.

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyRuleSet
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Ruleset File")]
        [String]$Ruleset
    )
    Process{
        Try{
            If (Test-Path -Path $Ruleset){
                $myRuleset = Get-Content $Ruleset -Raw | ConvertFrom-Json
                If(Test-isValidRuleSet -Object $myRuleset){
                    return $myRuleset
                }
                Else{
                    Write-Warning -Message ($Script:messages.InvalidRuleset -f $Ruleset)
                }
            }
            Else{
                Write-Warning -Message ($Script:messages.UnableToImportRuleset -f $Ruleset)
            }
        }
        Catch{
            Write-Warning -Message ($Script:messages.InvalidRuleset -f $Ruleset)
        }
    }
}

