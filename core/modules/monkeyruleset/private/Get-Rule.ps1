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

Function Get-Rule{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-Rule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.IO.FileInfo]$file,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$rule_file
    )
    Begin{
        try{
            $shadow_rule = (Get-Content $file.FullName -Raw) | ConvertFrom-Json
            $ValidRule = Test-isValidRule -Rule $shadow_rule;
        }
        catch{
            Write-Warning -Message ($Script:messages.InvalidRuleFound -f $rule_file.Name)
            Write-Verbose $_.Exception
            Write-Debug $_.Exception.StackTrace
            $shadow_rule = $null
            $ValidRule = $false
        }
        $found_args = $rule_file.Value | Select-Object -ExpandProperty args -ErrorAction Ignore
        $total_rules = @()
    }
    Process{
        try{
            if($ValidRule){
                foreach ($element in $rule_file.Value){
                    $raw_rule = (Get-Content $file.FullName -Raw)
                    $level = $element | Select-Object -ExpandProperty level -ErrorAction Ignore
                    $is_rule_enabled = $element | Select-Object -ExpandProperty enabled -ErrorAction Ignore
                    $compliance = $element | Select-Object -ExpandProperty compliance -ErrorAction Ignore
                    if($null -ne $is_rule_enabled -and $is_rule_enabled){
                        if($null -ne $found_args){
                            $count = 0;
                            foreach($_args in $element.args[0..($shadow_rule.arg_names.Count - 1)]){
                                foreach($arg in $_args){
                                    if($arg){
                                        $string_replace= ('(?<Item>_ARG_{0}_)' -f $count)
                                        $count+=1
                                        $raw_rule = $raw_rule -replace $string_replace,$arg
                                    }
                                    else{
                                        $string_replace= ('(?<Item>_ARG_{0}_)' -f $count)
                                        $count+=1
                                        $raw_rule = $raw_rule -replace $string_replace,""
                                    }
                                }
                            }
                        }
                        #Create JSON rule
                        $new_json_rule = $raw_rule | ConvertFrom-Json
                        if($null -ne $level){
                            $new_json_rule | Add-Member -Type NoteProperty -name level -value $level -Force
                        }
                        else{
                            Write-Warning -Message ($Script:messages.LevelNotSet -f $rule_file.Name)
                            $new_json_rule | Add-Member -Type NoteProperty -name level -value "Info" -Force
                        }
                        #Updating Compliance
                        if($null -ne $compliance){
                            Write-Verbose -Message ($Script:messages.UpdatingComlianceMessage -f $rule_file.Name)
                            $new_json_rule | Add-Member -Type NoteProperty -name compliance -value $compliance -Force
                        }
                        #Add to array
                        $total_rules+=$new_json_rule
                    }
                }
            }
            else{
                Write-Warning -Message ($Script:messages.InvalidRuleFound -f $rule_file.Name)
            }
        }
        catch{
            Write-Warning -Message ($Script:messages.InvalidRuleFound -f $rule_file.Name)
            Write-Verbose $_.Exception
            Write-Debug $_
        }
    }
    End{
        return $total_rules
    }
}
