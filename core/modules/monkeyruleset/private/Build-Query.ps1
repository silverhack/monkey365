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

Function Build-Query{
    <#
        .SYNOPSIS
        Resolve statement

        .DESCRIPTION
        Resolve statement

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
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, ParameterSetName = 'RuleObject', HelpMessage="Rule object")]
        [Object]$InputObject
    )
    try{
        if($PSCmdlet.ParameterSetName -eq 'RuleObject' -and $PSBoundParameters['InputObject']){
            #Set new obj
            $tmp_object = [ordered]@{}
            foreach($elem in $InputObject.Psobject.Properties){
                [void]$tmp_object.Add($elem.Name,$elem.Value)
            }
            $InputObject = New-Object -TypeName PSCustomObject -Property $tmp_object
            $unitCondition = $InputObject.conditions;
            if($unitCondition){
                $newQuery = ConvertTo-Query -Conditions $unitCondition
                if($newQuery){
                    $safeQuery = $newQuery | ConvertTo-ScriptBlock
                    if($safeQuery){
                        $InputObject | Add-Member -type NoteProperty -name query -value $safeQuery
                        return $InputObject
                    }
                    else{
                        Write-Warning -Message ($Script:messages.BuildQueryErrorMessage -f $rule.displayName)
                    }
                }
            }
        }
        elseif($null -ne (Get-Variable -Name AllRules -ErrorAction Ignore)){
            foreach($unitRule in $Script:AllRules){
                Write-Verbose -Message ($Script:messages.BuildQueryMessage -f $unitRule.displayName)
                $unitCondition = $unitRule.conditions;
                if($unitCondition){
                    $newQuery = ConvertTo-Query -Conditions $unitCondition
                    if($newQuery){
                        $safeQuery = $newQuery | ConvertTo-ScriptBlock
                    }
                    if($safeQuery){
                        $unitRule | Add-Member -type NoteProperty -name query -value $safeQuery
                    }
                    else{
                        Write-Warning -Message ($Script:messages.BuildQueryErrorMessage -f $unitRule.displayName)
                    }
                }
            }
        }
        else{
            Write-Warning $Script:messages.UnableToGetRules
        }
    }
    catch{
        Write-Error $_
    }
}
