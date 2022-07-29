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


Function Get-RulesFromRuleSet{
    <#
        .SYNOPSIS
		Get rules from ruleset file. Check for every single rule if args are present, if rule enabled, etc..

        .DESCRIPTION
		Get rules from ruleset file. Check for every single rule if args are present, if rule enabled, etc..

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-RulesFromRuleSet
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$ruleset,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$rulepath
    )
    Process{
        #$total_rules = @()
        foreach($rule_file in $ruleset){
            $fileName = $rule_file | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
            if($null -ne $fileName){
                $file = Get-RuleFromFile -fileName $fileName -rulepath $rulepath
                if($file -is [System.IO.FileInfo]){
                    Get-Rule -file $file -rule_file $rule_file
                }
            }
            else{
                Write-Warning -Message $Script:messages.UnableToGetObjectProperty
            }
        }
    }
}
