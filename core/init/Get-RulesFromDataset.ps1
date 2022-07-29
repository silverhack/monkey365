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


Function Get-RulesFromDataset{
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
            File Name	: Get-RulesFromDataset
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.IO.FileInfo]$rulefile,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$rulePath
    )
    Begin{
        $all_json_rules = @()
        $all_files = @()
        $ruleset_ = (Get-Content $rulefile -Raw) | ConvertFrom-Json
        if($null -ne $ruleset_.psobject.Properties.Item('partials')){
            foreach($element in $ruleset_.partials.GetEnumerator()){
                $msg = @{
                    MessageData = ("Getting rules from {0}" -f $element)
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    Tags = @('NewRuleSetFileFound');
                    InformationAction = $InformationAction;
                }
                Write-Information @msg
                $isRoot = [System.IO.Path]::IsPathRooted($element)
                if(-NOT $isRoot){
                    $rules_path = ("{0}/rules/rulesets/{1}" -f $O365Object.Localpath, $element)
                }
                else{
                    $rules_path = $element
                }
                $all_files += $rules_path
            }
        }
        #Getting rules for each file
        foreach($element in $all_files){
            $new_ruleset = (Get-Content $element -Raw) | ConvertFrom-Json
            $jsonrules = $new_ruleset.rules.psobject.Properties | Select-Object Name, Value
            $unit_rules = Get-RulesFromRuleSet -ruleset $jsonrules -rulepath $rulePath -Verbose -Debug
            if($unit_rules){
                $all_json_rules+=$unit_rules
            }
        }
    }
    Process{
        #Getting rest of rules
        if($null -ne $ruleset_.psobject.Properties.Item('rules')){
            $jsonrules = $ruleset_.rules.psobject.Properties | Select-Object Name, Value
            $unit_rules = Get-RulesFromRuleSet -ruleset $jsonrules -rulepath $rulePath -Verbose -Debug
            if($unit_rules){
                $all_json_rules+=$unit_rules
            }
        }
        #Remove duplicates
        $all_json_rules = $all_json_rules | Sort-Object -Property issue_name -Unique
    }
    End{
        return $all_json_rules
    }
}
