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

function Build-Query{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Build-Query
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Scope="Function")]
    [OutputType([System.Management.Automation.ScriptBlock])]
    Param (
        [parameter(Mandatory=$true, HelpMessage="Conditions")]
        [object]$conditions,

        [parameter(Mandatory=$true, HelpMessage="Conditions directory path")]
        [string]$conditions_path
    )
    $new_filter = @()
    $pass_filter = $null
    $first_verb = $conditions[0]
    $pass_nested_filter = ""
    foreach($condition in $conditions[1..($conditions.length -1)]){
        $is_filter = Test-IsNewFilter -conditions $condition
        if($is_filter){
            try{
                if($condition.Length -eq 2){$condition+=[string]::Empty}
                $prepare_filter = [ordered]@{
                    element_to_check = $condition[0];
                    verb = $condition[1];
                    value = $condition[2];
                }
                if($prepare_filter.element_to_check.Contains("_INCLUDE_") -and $conditions_path){
                    $include = Resolve-Include -include_file $prepare_filter.element_to_check `
                                               -conditions_path $conditions_path
                    $new_filter+=$include
                    continue;
                }
                $filter = Get-NewFilter @prepare_filter
                $new_filter+=$filter
            }
            catch{
                Write-warning $Script:messages.BuildQueryErrorMessage
                #Verbose
                Write-Verbose -Message $_
                continue
            }
        }
        else{
            #Potentially nested filter
            $first = (@($new_filter) -join (' -{0} ' -f $first_verb))
            $nested_filter = Get-NestedFilter -condition $condition -conditions_path $conditions_path
            if($nested_filter){
                $pass_nested_filter += $nested_filter
            }
        }
    }
    if($pass_nested_filter){
        $pass_filter = ("({0}) {1}" -f $first, $pass_nested_filter)
        #Write-Host $pass_filter -ForegroundColor Yellow
        try{
            return [ScriptBlock]::Create($pass_filter)
        }
        catch{
            #Verbose
            Write-Verbose -Message $_
            #debug
            Write-Debug -Message $_.Exception.StackTrace
        }
    }
    else{
        try{
            $pass_filter = (@($new_filter) -join (' -{0} ' -f $first_verb))
            if($null -ne $pass_filter -and $pass_filter.substring(2,1) -eq "-"){
                $pass_filter = $pass_filter.substring(6,($pass_filter.Length -8))
            }
            #Write-Host $pass_filter -ForegroundColor Magenta
            try{
                return [ScriptBlock]::Create($pass_filter)
            }
            catch{
                #Verbose
                Write-Verbose -Message $_
            }
        }
        catch{
            Write-warning $Script:messages.BuildQueryErrorMessage
            #Verbose
            Write-Verbose -Message $_
        }
    }
}
