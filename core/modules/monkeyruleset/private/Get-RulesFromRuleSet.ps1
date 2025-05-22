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
    [CmdletBinding()]
    Param ()
    Begin{
        $all_rules = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        #Get all rules
        foreach($unitRule in $Script:SecBaseline.rules){
            [void]$all_rules.Add($unitRule)
        }
        #Check if extended
        $extended_rules = $Script:SecBaseline | Select-Object -ExpandProperty extends -ErrorAction Ignore
    }
    Process{
        if($null -ne $extended_rules){
            foreach($element in $extended_rules){
                $msg = @{
                    MessageData = ($Script:messages.AdditionalRulesMessage -f $element)
                    InformationAction = $InformationAction;
                }
                Write-Information @msg
                $isRoot = [System.IO.Path]::IsPathRooted($element)
                if(-NOT $isRoot){
                    $rpath = [System.IO.DirectoryInfo]::new($Script:RulesetsPath);
                    if($rpath.GetFiles($element)){
                        $newFile = $rpath.GetFiles($element)
                        $newRule = $newFile.FullName.ToString()
                    }
                    else{
                        Write-Warning ($Script:messages.FileNotFound -f $element,$Script:Rulesets)
                    }
                }
                else{
                    $newRule = $element
                }
                $p = @{
                    Ruleset = $newRule;
                }
                $newRuleSet = Get-MonkeyRuleSet @p
                if($newRuleSet){
                    [void]$all_rules.Add($newRuleSet.rules)
                }
            }
        }
    }
    End{
        #Remove duplicates
        $all_rules = $all_rules | Select-Object * -Unique
        #Get rules
        foreach($rule in @($all_rules)){
            $_rules = $rule.Psobject.Properties | Select-Object Name,Value
            if($_rules){
                foreach($rule in $_rules){
                    $p = @{
                        FileName = $rule.Name
                        RulePath = $Script:FindingsPath;
                    }
                    $myRule = Get-File @p
                    if($myRule){
                        $rule | Add-Member -Type NoteProperty -name File -value $myRule -Force
                        #Get rule info
                        $rule | Get-MonkeyRule
                    }
                }
            }
        }
    }
}

