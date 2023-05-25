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

Function Get-NestedFilter{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-NestedFilter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$true, HelpMessage="Condition")]
        [object]$condition,

        [parameter(Mandatory=$false, HelpMessage="Conditions directory path")]
        [string]$conditions_path
    )
    try{
        #create array
        $new_nested_filter = @()
        [array]$indexed_operators = [Linq.Enumerable]::Where(
            [Linq.Enumerable]::Range(0, $condition.Length),
            [Func[int, bool]] { param($i)
                                $condition[$i] -eq 'or' -or $condition[$i] -eq 'and'
                                }
        )
        for($i=0;$i -lt $condition.length;$i++){
            if($i -in $indexed_operators -and $condition[$i] -is [System.String]){
                #Potentially new operator found
                $new_operator = ("-{0}" -f $condition[$i])
            }
            elseif($i -in $indexed_operators -and $condition[$i] -is [System.Array]){
                $nested_filter = @()
                $operator = $condition[$i][0]
                $nested = $condition[$i]
                foreach($new_condition in $nested[1..($nested.length -1)]){
                    $prepare_filter = [ordered]@{
                        element_to_check = $new_condition[0];
                        verb = $new_condition[1];
                        value = $new_condition[2];
                    }
                    if($prepare_filter.element_to_check.Contains("_INCLUDE_") -and $conditions_path){
                        $include = Resolve-Include -include_file $prepare_filter.element_to_check `
                                                   -conditions_path $conditions_path
                        $nested_filter+=$include
                        continue;
                    }
                    $filter = Get-NewFilter @prepare_filter
                    $nested_filter+=$filter
                }
                $translated_filter = (@($nested_filter) -join (' -{0} ' -f $operator))
                $my_filter = ("{0} ({1}) " -f $new_operator, $translated_filter)
                #add filter to nested string
                $new_nested_filter+=$my_filter
            }
        }
        if($new_nested_filter){
            return $new_nested_filter
        }
    }
    catch{
        Write-warning $Script:messages.UnableToGetNestedFilter
        #Write verbose
        Write-Verbose $_
    }
}
