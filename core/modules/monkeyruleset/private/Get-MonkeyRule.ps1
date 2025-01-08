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

Function Get-MonkeyRule{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyRule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True,HelpMessage="File name")]
        [Object]$Rule
    )
    Process{
        try{
            $shadow_rule = (Get-Content $Rule.File.FullName -Raw) | ConvertFrom-Json
            $ValidRule = $shadow_rule | Test-isValidRule;
        }
        catch{
            Write-Warning -Message ($Script:messages.InvalidRuleMessage -f $Rule.Name)
            Write-Verbose $_.Exception
            #Write-Debug $_.Exception.StackTrace
            $shadow_rule = $null
            $ValidRule = $false
        }
        try{
            if($ValidRule){
                foreach ($element in $Rule.Value){
                    $raw_rule = (Get-Content $Rule.File.FullName -Raw)
                    $found_args = $element | Select-Object -ExpandProperty args -ErrorAction Ignore
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
                        elseif($null -ne $new_json_rule.PsObject.Properties.Item('level') -and $null -eq $new_json_rule.level){
                            Write-Warning -Message ($Script:messages.LevelNotSet -f $Rule.File.Name)
                            $new_json_rule | Add-Member -Type NoteProperty -name level -value "Info" -Force
                        }
                        else{
                            #nothing to do here
                        }
                        #Updating Compliance
                        if($null -ne $compliance){
                            Write-Verbose -Message ($Script:messages.UpdatingComlianceMessage -f $Rule.File.Name)
                            $new_json_rule | Add-Member -Type NoteProperty -name compliance -value $compliance -Force
                        }
                        #Add file
                        $new_json_rule | Add-Member -Type NoteProperty -name File -value $Rule.File -Force
                        #return rule
                        $new_json_rule
                    }
                }
            }
            else{
                Write-Warning -Message ($Script:messages.InvalidRuleMessage -f $Rule.File.Name)
            }
        }
        catch{
            Write-Warning -Message ($Script:messages.InvalidRuleMessage -f $Rule.File.Name)
            Write-Verbose $_.Exception
            Write-Debug $_
        }
    }
}

