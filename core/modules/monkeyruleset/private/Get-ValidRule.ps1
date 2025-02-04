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

Function Get-ValidRule{
    <#
        .SYNOPSIS
        Remove unused rules

        .DESCRIPTION
        Remove unused rules

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ValidRule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    Try{
        If($null -ne (Get-Variable -Name AllRules -Scope Script -ErrorAction Ignore)){
            #Create new array
            $all_rules = [System.Collections.Generic.List[System.String]]::new()
            #Remove elements that are not present in dataset
            $all_paths = $Script:AllRules.rule | Select-Object -ExpandProperty path | Select-Object -Unique
            ForEach($elem in $all_paths){
                $exists = $Script:Dataset | Select-Object -ExpandProperty $elem -ErrorAction Ignore
                If($null -eq $exists){
                    #removing rule
                    Write-Verbose -Message ($Script:messages.UnitItemNotFound -f $elem)
                    #$all_rules += $elem
                    [void]$all_rules.Add($elem);
                }
            }
            @($Script:AllRules).Where({$_.rule.path -notin $all_rules})
        }
    }
    Catch{
        Write-Error $_
    }
}


