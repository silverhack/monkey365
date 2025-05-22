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

Function Invoke-UnitRule{
    <#
        .SYNOPSIS
        Scan a dataset with a number of rules

        .DESCRIPTION
        Scan a dataset with a number of rules

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-UnitRule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Ruleset Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$True, HelpMessage="Objects to check")]
        [Object]$ObjectsToCheck
    )
    Begin{
        $matched_elements = $null
    }
    Process{
        If($null -ne $InputObject.query){
            #Get Matched elements
            $matched_elements = Get-QueryResult -InputObject $ObjectsToCheck -Query $InputObject.query
            #Get extra validation
            $moreThan = $InputObject.rule | Select-Object -ExpandProperty moreThan -ErrorAction Ignore | Convert-Value
            $lessThan = $InputObject.rule | Select-Object -ExpandProperty lessThan -ErrorAction Ignore | Convert-Value
            $shouldExist = $InputObject.rule | Select-Object -ExpandProperty shouldExist -ErrorAction Ignore
            $returnObject = $InputObject.rule | Select-Object -ExpandProperty returnObject -ErrorAction Ignore
            $showAll = $InputObject.rule | Select-Object -ExpandProperty showAll -ErrorAction Ignore
            #Check for moreThan exception rule
            If($null -ne $moreThan){
                $count = @($matched_elements).Count
                if($count -le $moreThan){
                    $matched_elements = $null
                }
            }
            #Check for lessThan exception rule
            ElseIf($null -ne $lessThan){
                $count = @($matched_elements).Count
                If($null -eq $count){$count = 1}
                If($count -gt $lessThan){
                    $matched_elements = $null
                }
            }
            #Check for shouldExists exception rule
            If($null -ne $shouldExist){
                If($null -eq $matched_elements){
                    If($null -ne $returnObject){
                        $_retObj = New-Object -TypeName PSCustomObject
                        Foreach($element in $returnObject.psObject.Properties){
                            $_retObj | Add-Member -Type NoteProperty -name $element.Name -value $element.Value
                        }
                        $matched_elements = $_retObj
                    }
                    Elseif($null -eq $returnObject){
                        $matched_elements = $ObjectsToCheck
                    }
                    Elseif($null -ne $showAll -and $showAll){
                        $matched_elements = $ObjectsToCheck
                    }
                }
                Else{
                    #return null
                    return $null
                }
            }
            #Return matched elements
            return $matched_elements
        }
        Else{
            Write-Warning -Message ($Script:messages.EmptyRuleGenericMessage -f $InputObject.idSuffix)
        }
    }
    End{
        #Nothing to do here
    }
}
