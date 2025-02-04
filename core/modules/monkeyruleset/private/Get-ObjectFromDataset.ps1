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

Function Get-ObjectFromDataset{
    <#
        .SYNOPSIS
        Get object from dataset

        .DESCRIPTION
        Get object from dataset

        .INPUTS
        String object with the element to search

        .OUTPUTS
        Element from dataset (PsObject/Array/String/Etc)

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ObjectFromDataset
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, ValueFromPipeline = $True, HelpMessage="Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Get metadata object")]
        [Switch]$Metadata
    )
    Process{
        Try{
            If($null -ne (Get-Variable -Name Dataset -Scope Script -ErrorAction Ignore)){
                If($PSBoundParameters.Keys.Count -eq 0){
                    $Script:Dataset
                }
                Else{
                    If($InputObject.rule.path -is [System.String] -and $InputObject.rule.path.Length -gt 0){
                        $objectsToCheck = $dataObjects = $subPath = $selectCondition = $null;
                        #Get first path
                        $objectsToCheck = Get-ObjectPropertyByPath -InputObject $Script:Dataset -Property $InputObject.rule.path
                        If($null -ne $objectsToCheck){
                            #Check if metadata only
                            If($PSBoundParameters.ContainsKey('Metadata') -and $PSBoundParameters['Metadata'].IsPresent){
                                If(([System.Collections.IDictionary]).IsAssignableFrom($objectsToCheck.GetType())){
                                    $objectsToCheck.Item('Metadata')
                                    return
                                }
                                ElseIf(($objectsToCheck.GetType() -eq [System.Management.Automation.PSCustomObject] -or $objectsToCheck.GetType() -eq [System.Management.Automation.PSObject])){
                                    $objectsToCheck | Select-Object -ExpandProperty 'Metadata' -ErrorAction Ignore
                                    return
                                }
                                Else{##Object isn't an hashtable, collection, etc...
                                    Write-Warning -Message ($Script:messages.UnableToGetMetadataInfo -f $InputObject.displayName)
                                    return $null
                                }
                            }
                            #Check if subPath exists
                            $subPath = $InputObject.rule | Select-Object -ExpandProperty subPath -ErrorAction Ignore
                            #Check if Select condition is present
                            $selectCondition = $InputObject.rule | Select-Object -ExpandProperty selectCondition -ErrorAction Ignore
                            #Check if Data property exists
                            $dataObjects = $objectsToCheck | Select-Object -ExpandProperty Data -ErrorAction Ignore
                            If($null -eq $dataObjects){
                                $dataObjects = $objectsToCheck
                            }
                            If($null -ne $dataObjects){
                                If($null -ne $subPath){
                                    #Get Subpath
                                    $dataObjects = Get-ObjectPropertyByPath -InputObject $dataObjects -Property $subPath.Trim()
                                }
                                If($null -ne $selectCondition -and $selectCondition.PsObject.Properties.GetEnumerator().MoveNext()){
                                    $queryTxt = convertFrom-Condition -Conditions $selectCondition -Operator "or"
                                    If($null -ne $queryTxt){
                                        $query = $queryTxt | ConvertTo-SecureScriptBlock
                                        If($null -ne $query){
                                            $dataObjects = @($dataObjects).Where($query)
                                        }
                                    }
                                }
                                #return dataObjects
                                return $dataObjects
                            }
                        }
                        Else{
                            Write-Warning -Message ($Script:messages.PathNotFoundErrorMessage -f $InputObject.rule.path.Trim().ToString())
                        }
                    }
                }
            }
            Else{
                Write-Warning $Script:messages.DatasetNotCreated
            }
        }
        Catch{
            Write-Error $_
        }
    }
}

