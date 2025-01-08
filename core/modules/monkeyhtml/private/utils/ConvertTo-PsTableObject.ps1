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

Function ConvertTo-PsTableObject {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-PsTableObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("InjectionRisk.Create", "", Scope="Function")]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Object")]
        [Object]$InputObject
    )
    Process{
        $expressions = [System.Collections.Generic.List[System.Object]]::new()
        $elementsToCheck = $myPsObject = $null;
        $expand = $InputObject | Select-Object -ExpandProperty expandObject -ErrorAction Ignore
        #Check for limits
        if($null -ne $InputObject.actions.objectData.PsObject.Properties.Item('limit') -and $null -ne $InputObject.actions.objectData.limit){
            [int]$int_min_value = [int32]::MinValue;
            [bool]$integer = [int]::TryParse($InputObject.actions.objectData.limit, [ref]$int_min_value);
            if($integer){
                $elementsToCheck = $InputObject.affectedResources | Select-Object -First $InputObject.actions.objectData.limit
            }
            else{
                Write-Verbose "Unable to limit objects"
            }
        }
        else{
            $elementsToCheck = $InputObject.affectedResources
        }
        If($null -ne $InputObject.translate -and $null -ne $elementsToCheck){
            if($expand){
                foreach($prop in $InputObject.translate.Psobject.Properties){
                    if($prop.Name.StartsWith($expand)){
                        $propName = $prop.Name.Replace(("{0}." -f $expand),'')
                        $newExpression = [ordered]@{
                            Name = $prop.value;
                            Expression = [scriptblock]::Create(('$_.{0}' -f $propName))
                        }
                        [void]$expressions.Add($newExpression);
                    }
                    else{
                        $newExpression = [ordered]@{
                            Name = $prop.value;
                            Expression = [scriptblock]::Create(('$elem.{0}' -f $prop.Name))
                        }
                        [void]$expressions.Add($newExpression);
                    }
                }
            }
            else{
                foreach($prop in $InputObject.translate.Psobject.Properties){
                    $newExpression = [ordered]@{
                        Name = $prop.value;
                        Expression = [scriptblock]::Create(('$_.{0}' -f $prop.Name))
                    }
                    [void]$expressions.Add($newExpression);
                }
            }
        }
        if($expressions.Count -gt 0 -and $null -ne $elementsToCheck){
            $p = @{
                InputObject = $elementsToCheck;
                Expressions = $expressions;
                Expand = $expand;
            }
            $myPsObject = ConvertFrom-PsExpression @p
        }
        if(($myPsObject | Test-IsNullPsObject) -eq $false){
            foreach($obj in @($myPsObject)){
                foreach($elem in $obj.PsObject.Properties){
                    #Update psObject (escape values, convert to URI format, etc..)
                    $value = $elem.Value | Format-PsObject
                    if($value -is [System.Collections.IEnumerable] -and $value -isnot [string]){
                        $value = (@($value) -join ',')
                    }
                    $elem.Value = $value
                }
            }
            Write-Output $myPsObject -NoEnumerate
        }
    }
}

