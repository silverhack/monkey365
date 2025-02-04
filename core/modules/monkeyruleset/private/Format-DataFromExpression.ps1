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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
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
        [String]$ExpandObject,

        [Parameter(Mandatory=$false, HelpMessage="Excluded properties")]
        [System.Array]$ExcludedProperties = @("Raw","RawData","raw_data","rawPolicy","rawObject"),

        [Parameter(Mandatory=$false, HelpMessage="Limit objects")]
        [AllowNull()]
        [System.Int32]$Limit,

        [Parameter(Mandatory=$false, HelpMessage="Expand object")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$DisplayName
    )
    Process{
        Set-StrictMode -Off
        $allExpressions = [System.Collections.Generic.List[System.Object]]::new()
        #Set null
        $_expressions = $null;
        #check if PsObject
        $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($PSBoundParameters['Expressions'].GetType())
        #check if PsObject
        $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($PSBoundParameters['Expressions'].GetType())
        If(-NOT $isPsCustomObject -and -NOT $isPsObject){
            #Check if dictionary
            If(([System.Collections.IDictionary]).IsAssignableFrom($Expressions.GetType())){
                #Check if * in properties
                If($PSBoundParameters['Expressions'].Values.Where({$_ -eq "*"}) -or $PSBoundParameters['Expressions'].keys.Where({$_ -eq "*"})){
                    $_expressions = "*"
                }
                Else{
                    #Set new psObject
                    $_expressions = New-Object -TypeName PSCustomObject -Property $PSBoundParameters['Expressions']
                }
            }
            ## Iterate over all child objects in cases in which InputObject is an array
            ElseIf ($PSBoundParameters['Expressions'] -is [System.Collections.IEnumerable] -and $PSBoundParameters['Expressions'] -isnot [string]){
                If($PSBoundParameters['Expressions'].Contains('*')){
                    $_expressions = "*"
                }
                ElseIf($PSBoundParameters['Expressions'].Count -eq 0){
                    $_expressions = "*"
                }
                Else{
                    Try{
                        $props = [ordered]@{}
                        Foreach($expr in $PSBoundParameters['Expressions']){
                            If(![System.String]::IsNullOrEmpty($expr)){
                                [void]$props.Add($expr,$expr);
                            }
                        }
                        #Set new psObject
                        $_expressions = New-Object -TypeName PSCustomObject -Property $props
                    }
                    Catch{
                        Write-Error "Unable to format expression from array"
                    }
                }
            }
            ElseIf($PSBoundParameters['Expressions'] -is [System.String]){
                If($PSBoundParameters['Expressions'] -eq '*'){
                    $_expressions = "*"
                }
                ElseIf([System.String]::IsNullOrEmpty($PSBoundParameters['Expressions'])){
                    $_expressions = "*"
                }
                ElseIf([System.String]::IsNullOrWhiteSpace($PSBoundParameters['Expressions'])){
                    $_expressions = "*"
                }
                Else{
                    Try{
                        $props = [ordered]@{}
                        [void]$props.Add($PSBoundParameters['Expressions'],$PSBoundParameters['Expressions']);
                        #Set new psObject
                        $_expressions = New-Object -TypeName PSCustomObject -Property $props
                    }
                    Catch{
                        Write-Error "Unable to format expression from string"
                    }
                }
            }
            Else{
                Write-Warning "Unable to evaluate expressions"
            }
        }
        Else{
            If($PSBoundParameters['Expressions'].PsObject.Properties.Name -match "\*"){
                $_expressions = "*"
            }
            ElseIf(-not $PSBoundParameters['Expressions'].PsObject.Properties.GetEnumerator().MoveNext()){
                #Empty psObject
                $_expressions = "*"
            }
            Else{
                $_expressions = $PSBoundParameters['Expressions'];
            }
        }
        #Evaluate expressions
        Try{
            If($null -ne $_expressions){
                #String expressions won't be evaluated
                If($_expressions -isnot [System.String]){
                    If($PSBoundParameters.ContainsKey('ExpandObject') -and $PSBoundParameters['ExpandObject'] -and ($isPsCustomObject -or $isPsObject)){
                        ForEach($element in $_expressions.PsObject.Properties){
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
                        foreach($element in $_expressions.PsObject.Properties){
                            <#
                            If($element.Name.Trim().ToString().Contains('@') -or $element.Name.Trim().ToString().Contains('.')){
                                $newExpression = [ordered]@{
                                    Name = $element.value;
                                    Expression = [scriptblock]::Create(('$_."{0}"' -f $element.Name))
                                }
                                [void]$allExpressions.Add($newExpression);
                            }
                            #>
                            If($element.Name.Trim().ToString().Contains('@')){
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
                    #Add expression
                    [void]$allExpressions.Add($_expressions);
                }
            }
            Else{
                Write-warning "Unable to evaluate expressions"
            }
            #Evaluate expressions
            If($allExpressions.Count -gt 0){
                $_allItems = $null;
                If($PSBoundParameters.ContainsKey('ExpandObject') -and $PSBoundParameters['ExpandObject']){
                    foreach($elem in @($InputObject)){
                        If($PSBoundParameters['ExpandObject'].Trim().ToString().Contains('.')){
                            If(($elem.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                                $subelements = $elem.GetPropertyByPath($PSBoundParameters['ExpandObject'].Trim())
                                If($null -ne $subelements){
                                    $_allItems = $subelements | Select-Object $allExpressions -ErrorAction SilentlyContinue
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
                                $_allItems = $subelements | Select-Object $allExpressions -ErrorAction SilentlyContinue
                            }
                        }
                    }
                }
                Else{
                    ForEach($newItem in @($InputObject)){
                        $_allItems = $newItem | Select-Object $allExpressions -ErrorAction SilentlyContinue
                    }
                }
                #Excluded properties
                If($null -ne $_allItems){
                    If($PSBoundParameters.ContainsKey('Limit') -and $PSBoundParameters['Limit']){
                        $_allItems | Select-Object * -ExcludeProperty $ExcludedProperties -First $PSBoundParameters['Limit'] -ErrorAction Ignore
                    }
                    Else{
                        $_allItems | Select-Object * -ExcludeProperty $ExcludedProperties -ErrorAction Ignore
                    }
                }
            }
            Else{
                Write-Warning "Unable to get expressions"
            }
        }
        Catch{
            Write-Error $_
            Write-Warning "Unable to get expressions from object"
        }
    }
}

