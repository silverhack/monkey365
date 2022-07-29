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

Function Resolve-Include{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-Include
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$true, HelpMessage="Include file")]
        [string]$include_file,

        [parameter(Mandatory=$true, HelpMessage="Conditions Path")]
        [string]$conditions_path
    )
    $new_filter = @()
    $pass_filter = $null
    $pass_nested_filter = ""
    $inc_file = $include_file.Split("(").split(")")[1]
    $conditions_file = ("{0}/{1}" -f $conditions_path, $inc_file.ToString())
    $file_exists = [System.IO.File]::Exists($conditions_file)
    if($file_exists){
        try{
            $new_conditions = (Get-Content $conditions_file -Raw) | ConvertFrom-Json
            $first_verb = $new_conditions.conditions[0]
            foreach($condition in $new_conditions.conditions[1..($new_conditions.conditions.length -1)]){
                $is_filter = Test-IsNewFilter -conditions $condition
                if($is_filter){
                    if($condition.Length -eq 2){$condition+=[string]::Empty}
                    $prepare_filter = [ordered]@{
                        element_to_check = $condition[0];
                        verb = $condition[1];
                        value = $condition[2];
                    }
                    $filter = Get-NewFilter @prepare_filter
                    $new_filter+=$filter
                }
                else{
                    $first = (@($new_filter) -join (' -{0} ' -f $first_verb))
                    $nested_filter = Get-NestedFilter -condition $condition
                    if($nested_filter){
                        $pass_nested_filter += $nested_filter
                    }
                }
            }
            if($pass_nested_filter){
                $pass_filter = ("{0} {1}" -f $first, $pass_nested_filter)
                return [ScriptBlock]::Create(("({0})" -f$pass_filter))
                #return $pass_filter
            }
            else{
                $pass_filter = (@($new_filter) -join (' -{0} ' -f $first_verb))
                return [ScriptBlock]::Create(("({0})" -f$pass_filter))
                #return $pass_filter
            }
        }
        catch{
            Write-warning ($Script:messages.InvalidCondition -f $inc_file)
            #Write verbose
            Write-Verbose $_
        }
    }
}
