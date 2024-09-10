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

Function Format-DataFromExpression {
    <#
        .SYNOPSIS
        Construct a PowerShell expression from a psObject object and format data

        .DESCRIPTION
        Construct a PowerShell expression from a psObject object and format data

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Format-DataFromExpression
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="data object")]
        [Object]$InputObject,

        [Parameter(Mandatory=$true, HelpMessage="Expressions object")]
        [AllowNull()]
        [Object]$Expressions,

        [Parameter(Mandatory=$false, HelpMessage="Expand object")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$ExpandObject
    )
    Process{
        $allExpressions = [System.Collections.Generic.List[System.Object]]::new()
        Set-StrictMode -Off
        #check if PsObject
        $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($InputObject.GetType())
        #check if PsObject
        $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($InputObject.GetType())
        If(-NOT $isPsCustomObject -and -NOT $isPsObject){
            return $allExpressions
        }
        Try{
            If($PSBoundParameters.ContainsKey('Expressions') -and $PSBoundParameters['Expressions']){
                If($PSBoundParameters.ContainsKey('ExpandObject') -and $PSBoundParameters['ExpandObject']){
                    ForEach($element in $Expressions.PsObject.Properties){
                        If($element.Name.StartsWith($PSBoundParameters['ExpandObject'])){
                            $propName = $element.Name.Replace(("{0}." -f $PSBoundParameters['ExpandObject']),'')
                            If($propName.Trim().ToString().Contains('@') -or $propName.Trim().ToString().Contains('.')){
                                $newExpression = [ordered]@{
                                    Name = $element.value;
                                    Expression = [scriptblock]::Create(('$_."{0}"' -f $propName))
                                }
                                [void]$allExpressions.Add($newExpression);
                            }
                            Else{
                                If($propName.Trim().ToString().Contains('@') -or $propName.Trim().ToString().Contains('.')){
                                    $newExpression = [ordered]@{
                                        Name = $element.value;
                                        Expression = [scriptblock]::Create(('$_."{0}"' -f $propName))
                                    }
                                    [void]$allExpressions.Add($newExpression);
                                }
                                Else{
                                    $newExpression = [ordered]@{
                                        Name = $element.value;
                                        Expression = [scriptblock]::Create(('$_.{0}' -f $propName))
                                    }
                                    [void]$allExpressions.Add($newExpression);
                                }
                            }
                        }
                        Else{
                            $newExpression = [ordered]@{
                                Name = $element.value;
                                Expression = [scriptblock]::Create(('$elem.{0}' -f $element.Name))
                            }
                            [void]$allExpressions.Add($newExpression);
                        }
                    }
                }
                Else{
                    foreach($element in $Expressions.PsObject.Properties){
                        If($element.Name.Trim().ToString().Contains('@') -or $element.Name.Trim().ToString().Contains('.')){
                            $newExpression = [ordered]@{
                                Name = $element.value;
                                Expression = [scriptblock]::Create(('$_."{0}"' -f $element.Name))
                            }
                            [void]$allExpressions.Add($newExpression);
                        }
                        Else{
                            $newExpression = [ordered]@{
                                Name = $element.value;
                                Expression = [scriptblock]::Create(('$_.{0}' -f $element.Name))
                            }
                            [void]$allExpressions.Add($newExpression);
                        }
                    }
                }
            }
            Else{
                return $null
            }
            #Evaluate expressions
            If($PSBoundParameters.ContainsKey('ExpandObject') -and $PSBoundParameters['ExpandObject']){
                foreach($elem in @($InputObject)){
                    If($PSBoundParameters['ExpandObject'].Trim().ToString().Contains('.')){
                        If(($elem.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                            $subelements = $elem.GetPropertyByPath($PSBoundParameters['ExpandObject'].Trim())
                            If($null -ne $subelements){
                                $subelements | Select-Object $allExpressions -ErrorAction SilentlyContinue
                            }
                        }
                        Else{
                            Write-Warning "GetPropertyByPath method was not loaded"
                        }
                    }
                    Else{
                        #Get element
                        $subelements = $elem | Select-Object -ExpandProperty $PSBoundParameters['ExpandObject'] -ErrorAction Ignore
                        if($null -ne $subelements){
                            $subelements | Select-Object $allExpressions -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
            Else{
                ForEach($newItem in @($InputObject)){
                    $newItem | Select-Object $allExpressions -ErrorAction SilentlyContinue
                }
            }
        }
        Catch{
            Write-Error $_
            Write-Warning "Unable to get expressions from object"
        }
    }
}
