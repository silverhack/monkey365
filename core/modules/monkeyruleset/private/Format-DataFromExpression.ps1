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

        [Parameter(Mandatory=$false, HelpMessage="Specifies the number of objects to select from the beginning of an array of input objects")]
        [AllowNull()]
        [System.Int32]$First,

        [Parameter(Mandatory=$false, HelpMessage="Specifies the number of objects to select from the end of an array of input objects.")]
        [AllowNull()]
        [System.Int32]$Last,

        [Parameter(Mandatory=$false, HelpMessage="Skips (doesn't select) the specified number of items.")]
        [AllowNull()]
        [System.Int32]$Skip,

        [Parameter(Mandatory=$false, HelpMessage="Selects objects from an array based on their index values.")]
        [AllowNull()]
        [System.Int32]$Index,

        [Parameter(Mandatory=$false, HelpMessage="Rule Name. Used for debug purposes")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$RuleName
    )
    Begin{
        Set-StrictMode -Off
        $allItems = [System.Collections.Generic.List[System.Object]]::new()
        #Create Select-Object new param
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Select-Object")
        $selectObjectParam = [ordered]@{}
        If($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys.Where({$_.ToLower() -ne "inputobject"})
            ForEach($p in $param.GetEnumerator()){
                If($PSBoundParameters.ContainsKey($p)){
                    $selectObjectParam.Add($p,$PSBoundParameters[$p])
                }
            }
        }
        #Internal Function
        Function Get-PsExpression {
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
                Try{
                    $allExpressions = [System.Collections.Generic.List[System.Object]]::new()
                    #Set null
                    $_expressions = $null;
                    If($null -ne $PSBoundParameters['Expressions']){
                        #Check if dictionary
                        If(([System.Collections.IDictionary]).IsAssignableFrom($PSBoundParameters['Expressions'].GetType())){
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
                                            If($expr.Trim().ToString().Contains('.')){
                                                [void]$props.Add($expr,$expr.Split('.')[-1].Trim().ToString());
                                            }
                                            Else{
                                                [void]$props.Add($expr,$expr);
                                            }
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
                                    If($PSBoundParameters['Expressions'].Trim().ToString().Contains('.')){
                                        [void]$props.Add($PSBoundParameters['Expressions'],$PSBoundParameters['Expressions'].Split('.')[-1].Trim().ToString());
                                    }
                                    Else{
                                        [void]$props.Add($PSBoundParameters['Expressions'],$PSBoundParameters['Expressions']);
                                    }
                                    #Set new psObject
                                    $_expressions = New-Object -TypeName PSCustomObject -Property $props
                                }
                                Catch{
                                    Write-Error "Unable to format expression from string"
                                }
                            }
                        }
                        ElseIf($PSBoundParameters['Expressions'] | Test-IsPsObject){
                            If($PSBoundParameters['Expressions'].PsObject.Properties.Name -match "\*"){
                                If($PSBoundParameters.ContainsKey('ExpandObject') -and $PSBoundParameters['ExpandObject']){
                                    $newHashTable = [ordered]@{}
                                    $_output = $newProps = $null
                                    If($PSBoundParameters['ExpandObject'].Trim().ToString().Contains('.')){
                                        If(($InputObject.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                                            $_output = $InputObject.GetPropertyByPath($PSBoundParameters['ExpandObject'].ToString().Trim())
                                        }
                                        Else{
                                            Write-Verbose "GetPropertyByPath method was not loaded"
                                        }
                                    }
                                    Else{
                                        $_output = $InputObject | Select-Object -ExpandProperty $PSBoundParameters['ExpandObject'] -ErrorAction Ignore
                                    }
                                    If($null -ne $_output){
                                        $newProps = $_output | Select-Object -First 1 -ErrorAction Ignore | Select-Object -Property {$_.Psobject.Properties.Name} | Select-Object -ExpandProperty '$_.Psobject.Properties.Name'
                                    }
                                    If($null -ne $newProps){
                                        #Create new object
                                        Foreach($elem in $PSBoundParameters['Expressions'].PsObject.Properties){
                                            If($elem.Name -notmatch $PSBoundParameters['ExpandObject']){
                                                [void]$newHashTable.Add($elem.Name,$elem.Value)
                                            }
                                        }
                                        Foreach($prop in $newProps){
                                            [void]$newHashTable.Add(("{0}.{1}" -f $PSBoundParameters['ExpandObject'],$prop),$prop)
                                        }
                                        #Create new object
                                        $_expressions = New-Object -TypeName PSCustomObject -Property $newHashTable
                                    }
                                    Else{
                                        Write-Verbose ("Unable to get PsObject properties from {0}. Empty object returned" -f $PSBoundParameters['ExpandObject'])
                                    }
                                }
                                Else{
                                    $_expressions = "*"
                                }
                            }
                            ElseIf(-not $PSBoundParameters['Expressions'].PsObject.Properties.GetEnumerator().MoveNext()){
                                #Empty psObject
                                $_expressions = "*"
                            }
                            Else{
                                $_expressions = $PSBoundParameters['Expressions'];
                            }
                        }
                        Else{
                            Write-Warning "Unable to evaluate expressions. Unrecognized expression object"
                        }
                    }
                    Else{
                        #Empty expressions object
                        $_expressions = "*"
                    }
                    If($null -ne $_expressions){
                        #String expressions won't be evaluated
                        If($_expressions | Test-IsPsObject){
                            If($PSBoundParameters.ContainsKey('ExpandObject') -and $PSBoundParameters['ExpandObject']){
                                ForEach($element in $_expressions.PsObject.Properties){
                                    $property = [System.Text.StringBuilder]::new()
                                    If($element.Name.StartsWith($PSBoundParameters['ExpandObject'])){
                                        $propName = $element.Name.Replace(("{0}." -f $PSBoundParameters['ExpandObject']),'')
                                        If($propName.Trim().ToString().Contains('@')){
                                            [void]$property.Append(('"{0}".' -f $propName.Trim().ToString()));
                                        }
                                        Else{
                                            ForEach($str in $propName.Split('.')){
                                                If($str.Trim().ToString().Contains(' ')){
                                                    [void]$property.Append(('"{0}".' -f $str.Trim().ToString()));
                                                }
                                                Else{
                                                    [void]$property.Append(("{0}." -f $str.Trim().ToString()));
                                                }
                                            }
                                        }
                                        #Remove last character
                                        $property.Length--;
                                        #Check for null
                                        If([System.String]::IsNullOrEmpty($element.value) -or [System.String]::IsNullOrWhiteSpace($element.Value)){
                                            $element.Value = $property.ToString().Split('.')[-1].Replace(' ','').Replace('"',"")
                                        }
                                        #Create expression
                                        Try{
                                            $newExpression = [ordered]@{
                                                Name = $element.value;
                                                Expression = [scriptblock]::Create(('$_.{0}' -f $property.ToString()))
                                            }
                                            [void]$allExpressions.Add($newExpression);
                                        }
                                        Catch{
                                            Write-Warning "Unable to create expression"
                                            Write-Warning $_.Exception.Message
                                        }
                                    }
                                    Else{
                                        If($element.Name.Trim().ToString().Contains('@')){
                                            [void]$property.Append(('"{0}".' -f $element.Name.Trim().ToString()));
                                        }
                                        Else{
                                            ForEach($str in $element.Name.Split('.')){
                                                If($str.Trim().ToString().Contains('@') -or $str.Trim().ToString().Contains(' ')){
                                                    [void]$property.Append(('"{0}".' -f $str.Trim().ToString()));
                                                }
                                                Else{
                                                    [void]$property.Append(("{0}." -f $str.Trim().ToString()));
                                                }
                                            }
                                        }
                                        #Remove last character
                                        $property.Length--;
                                        #Check for null
                                        If([System.String]::IsNullOrEmpty($element.value) -or [System.String]::IsNullOrWhiteSpace($element.Value)){
                                            $element.Value = $property.ToString().Split('.')[-1].Replace(' ','').Replace('"',"")
                                        }
                                        #Create new expression
                                        Try{
                                            $newExpression = [ordered]@{
                                                Name = $element.value;
                                                Expression = [scriptblock]::Create(('$elem.{0}' -f $property.ToString()))
                                            }
                                        }
                                        Catch{
                                            Write-Warning "Unable to create expression"
                                            Write-Warning $_.Exception.Message
                                        }
                                        [void]$allExpressions.Add($newExpression);
                                    }
                                }
                            }
                            Else{
                                ForEach($element in $_expressions.PsObject.Properties){
                                    #Set stringbuilder
                                    $property = [System.Text.StringBuilder]::new()
                                    If($element.Name.Trim().ToString().Contains('@')){
                                        [void]$property.Append(('"{0}".' -f $element.Name.Trim().ToString()));
                                    }
                                    Else{
                                        ForEach($str in $element.Name.Split('.')){
                                            If($str.Trim().ToString().Contains(' ')){
                                                [void]$property.Append(('"{0}".' -f $str.Trim().ToString()));
                                            }
                                            Else{
                                                [void]$property.Append(("{0}." -f $str.Trim().ToString()));
                                            }
                                        }
                                    }
                                    #Remove last character
                                    $property.Length--;
                                    If([System.String]::IsNullOrEmpty($element.value) -or [System.String]::IsNullOrWhiteSpace($element.Value)){
                                        $element.Value = $property.ToString().Split('.')[-1].Replace(' ','').Replace('"',"")
                                    }
                                    #Set new expression
                                    Try{
                                        $newExpression = [ordered]@{
                                            Name = $element.value;
                                            Expression = [scriptblock]::Create(('$_.{0}' -f $property.ToString()))
                                        }
                                        [void]$allExpressions.Add($newExpression);
                                    }
                                    Catch{
                                        Write-Warning "Unable to create expression"
                                        Write-Warning $_.Exception.Message
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
                        Write-Verbose "Unable to evaluate expression. An empty property or object was found"
                    }
                    #return Object
                    $allExpressions
                }
                Catch{
                    Write-Error $_
                    Write-Warning "Unable to get expressions from object"
                }
            }
        }
    }
    Process{
        #Create Get-PsExpression param
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-PsExpression")
        $psExpressionParam = [ordered]@{}
        If($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys.Where({$_.ToLower() -ne "inputobject"})
            ForEach($p in $param.GetEnumerator()){
                If($PSBoundParameters.ContainsKey($p)){
                    $psExpressionParam.Add($p,$PSBoundParameters[$p])
                }
            }
        }
        Try{
            If($PSBoundParameters.ContainsKey('ExpandObject') -and $PSBoundParameters['ExpandObject']){
                ForEach($elem in @($InputObject)){
                    #Get Expressions
                    $_expressions = $elem | Get-PsExpression @psExpressionParam
                    If($PSBoundParameters['ExpandObject'].Trim().ToString().Contains('.')){
                        If(($elem.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                            $subelements = $elem.GetPropertyByPath($PSBoundParameters['ExpandObject'].Trim())
                            If($null -ne $subelements){
                                $_allItems = $subelements | Select-Object $_expressions -ErrorAction SilentlyContinue
                                Foreach($item in @($_allItems)){
                                    [void]$allItems.Add($item);
                                }
                            }
                        }
                        Else{
                            Write-Verbose "GetPropertyByPath method was not loaded"
                        }
                    }
                    Else{
                        #Get element
                        $subelements = $elem | Select-Object -ExpandProperty $PSBoundParameters['ExpandObject'] -ErrorAction Ignore
                        If($null -ne $subelements){
                            $_allItems = $subelements | Select-Object $_expressions -ErrorAction Ignore
                            If($null -ne $_allItems){
                                Foreach($item in @($_allItems)){
                                    [void]$allItems.Add($item);
                                }
                            }
                        }
                    }
                }
            }
            Else{
                ForEach($newItem in @($InputObject)){
                    #Get Expressions
                    $_expressions = $newItem | Get-PsExpression @psExpressionParam
                    try{
                        $_allItems = $newItem | Select-Object $_expressions -ErrorAction SilentlyContinue
                        Foreach($item in @($_allItems)){
                            [void]$allItems.Add($item);
                        }
                    }
                    Catch{
                        Write-Error $_
                        Write-Warning "Unable to get expressions from object"
                    }
                }
            }
        }
        Catch{
            Write-Error $_
            Write-Warning "Unable to get expressions from object"
        }
    }
    End{
        #Excluded properties
        If($allItems.Count -gt 0){
            $allItems | Select-Object * -ExcludeProperty $ExcludedProperties @selectObjectParam -ErrorAction Ignore
        }
    }
}