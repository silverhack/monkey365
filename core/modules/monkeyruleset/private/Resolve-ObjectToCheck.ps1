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

Function Resolve-ObjectToCheck {
    <#
        .SYNOPSIS
		Querying the dataset using specific parameters such as path, subPath or criteria like selectCondition to retrieve desired information

        .DESCRIPTION
		Querying the dataset using specific parameters such as path, subPath or criteria like selectCondition to retrieve desired information

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-ObjectToCheck
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Rule object")]
        [Object]$InputObject,

        [Parameter(Mandatory=$true, HelpMessage="Objects to check")]
        [Object]$ObjectsToCheck
    )
    Process{
        $dataObjects = $subPath = $selectCondition = $null;
        Try{
            #Check if subPath exists
            $subPath = $InputObject | Select-Object -ExpandProperty subPath -ErrorAction Ignore
            #Check if Select condition is present
            $selectCondition = $InputObject | Select-Object -ExpandProperty selectCondition -ErrorAction Ignore
            #Check if Data property exists
            $dataObjects = $ObjectsToCheck | Select-Object -ExpandProperty Data -ErrorAction Ignore
            If($null -eq $dataObjects){
                $dataObjects = $ObjectsToCheck
            }
            If($null -ne $dataObjects){
                If($null -ne $subPath){
                    If($subPath.Trim().ToString().Contains('.')){
                        If(($dataObjects.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                            $dataObjects = $dataObjects.GetPropertyByPath($subPath.Trim())
                        }
                        Else{
                            Write-Warning "GetPropertyByPath method was not loaded"
                        }
                    }
                    Else{
                        #Get element
                        $dataObjects = $dataObjects | Select-Object -ExpandProperty $subPath.Trim() -ErrorAction Ignore
                    }
                }
                If($null -ne $selectCondition){
                    $queryTxt = convertFrom-Condition -Conditions $selectCondition -Operator "or"
                    if($null -ne $queryTxt){
                        $query = $queryTxt | ConvertTo-SecureScriptBlock
                        if($null -ne $query){
                            $dataObjects = @($dataObjects).Where($query)
                        }
                    }
                }
                #return dataObjects
                return $dataObjects
            }
        }
        Catch{
            Write-Error $_
        }
    }
}

