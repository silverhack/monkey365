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
        [parameter(Mandatory=$True, HelpMessage="Ruleset Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$True, HelpMessage="Objects to check")]
        [Object]$ObjectsToCheck
    )
    Begin{
        $matched_elements = $null
    }
    Process{
        if($null -ne $InputObject.query){
            #Get Matched elements
            $matched_elements = Get-QueryResult -InputObject $ObjectsToCheck -Query $InputObject.query
            #Check for moreThan exception rule
            if([bool]$InputObject.PSObject.Properties['moreThan']){
                $count = @($matched_elements).Count
                if($count -le $InputObject.moreThan){
                    $matched_elements = $null
                }
            }
            #Check for lessThan exception rule
            Elseif([bool]$InputObject.PSObject.Properties['lessThan']){
                $count = @($matched_elements).Count
                if($null -eq $count){$count = 1}
                if($count -gt $InputObject.lessThan){
                    $matched_elements = $null
                }
            }
            #Check for shouldExists exception rule
            if([bool]$InputObject.PSObject.Properties['shouldExist']){
                if($InputObject.shouldExist.ToString().ToLower() -eq "true"){
                    if($null -eq $matched_elements){
                        if([bool]$InputObject.PSObject.Properties['returnObject'] -and $null -ne $InputObject.returnObject){
                            $_retObj = New-Object -TypeName PSCustomObject
                            foreach($element in $InputObject.returnObject.psObject.Properties){
                                $_retObj | Add-Member -Type NoteProperty -name $element.Name -value $element.Value
                            }
                            $matched_elements = $_retObj
                        }
                        elseif([bool]$InputObject.PSObject.Properties['returnObject'] -and $null -eq $InputObject.returnObject){
                            $matched_elements = $ObjectsToCheck
                        }
                        elseif([bool]$InputObject.PSObject.Properties['showAll']){
                            if($InputObject.showAll.ToString().ToLower() -eq "true"){
                                $matched_elements = $ObjectsToCheck
                            }
                        }
                    }
                    else{
                        #Set matched element to null
                        $matched_elements= $null;
                    }
                }
            }
        }
        else{
            Write-Warning ("Empty rule in {0}" -f $InputObject.idSuffix)
        }
    }
    End{
        return $matched_elements
    }
}