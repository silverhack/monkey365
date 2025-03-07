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
        Build query

        .DESCRIPTION
        Build query

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
        [parameter(Mandatory=$false, ValueFromPipeline = $True, HelpMessage="Rule object")]
        [Object]$InputObject
    )
    Process{
        Try{
            If($PSBoundParameters.ContainsKey('InputObject') -and $PSBoundParameters['InputObject']){
                $ruleObj = $null;
                $shadowObj = $InputObject | Copy-PsObject
                #Get query object
                If(($shadowObj.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                    $ruleObj = $shadowObj.GetPropertyByPath('rule.query')
                    if($null -eq $ruleObj){
                        Write-Warning -Message ($Script:messages.BuildQueryErrorMessage -f $shadowObj.displayName)
                        return
                    }
                }
                Else{
                    Write-Warning -Message $Script:messages.MethodNotFound
                    return
                }
                #set new stringbuilder
                $finalquery = [System.Text.StringBuilder]::new()
                $newQuery = $ruleObj | ConvertTo-Query
                foreach($q in @($newQuery)){
                    [void]$finalquery.Append((" {0}" -f $q));
                }
                If($finalquery.Length -gt 0){
                    $safeQuery = $finalquery | ConvertTo-SecureScriptBlock
                    if($safeQuery){
                        $shadowObj | Add-Member -type NoteProperty -name query -value $safeQuery
                        return $shadowObj
                    }
                    else{
                        Write-Warning -Message ($Script:messages.BuildQueryErrorMessage -f $shadowObj.displayName)
                    }
                }
            }
            Elseif($null -ne (Get-Variable -Name AllRules -ErrorAction Ignore)){
                foreach($unitRule in $Script:AllRules){
                    $ruleObj = $null;
                    Write-Verbose -Message ($Script:messages.BuildQueryMessage -f $unitRule.displayName)
                    #Get query object
                    If(($unitRule.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                        $ruleObj = $unitRule.GetPropertyByPath('rule.query')
                        If($null -eq $ruleObj){
                            Write-Warning -Message ($Script:messages.BuildQueryErrorMessage -f $unitRule.displayName)
                            return
                        }
                    }
                    Else{
                        Write-Warning -Message $Script:messages.MethodNotFound
                        return
                    }
                    #Set new stringbuilder
                    $finalquery = [System.Text.StringBuilder]::new()
                    $newQuery = $ruleObj | ConvertTo-Query
                    foreach($q in @($newQuery)){
                        [void]$finalquery.Append((" {0}" -f $q));
                    }
                    If($finalquery.Length -gt 0){
                        $safeQuery = $finalquery.ToString() | ConvertTo-SecureScriptBlock
                        If($safeQuery){
                            $unitRule | Add-Member -type NoteProperty -name query -value $safeQuery
                        }
                        Else{
                            Write-Warning -Message ($Script:messages.BuildQueryErrorMessage -f $unitRule.displayName)
                        }
                    }
                }
            }
            Else{
                Write-Warning $Script:messages.UnableToGetRules
            }
        }
        Catch{
            Write-Error $_
        }
    }
}

