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

Function Resize-PsObject{
    <#
        .SYNOPSIS

        Resize psObject (remove elements, escape values, convert to URI format, etc..)

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resize-PsObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Object")]
        [Object]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage="Expand Object")]
        [AllowNull()]
        [String]$ExpandObject,

        [Parameter(Mandatory=$false, HelpMessage="Excluded properties")]
        [System.Array]$ExcludedProperties,

        [Parameter(Mandatory=$false, HelpMessage="Include properties")]
        [System.Array]$ExpandProperties
    )
    Process{
        Try{
            $selected_elements = $rawObjects = $null;
            If($PSBoundParameters.ContainsKey('ExpandObject') -and $null -ne $PSBoundParameters['ExpandObject']){
                $rawObjects = $InputObject | Select-Object -ExpandProperty $PSBoundParameters['ExpandObject'] -ErrorAction Ignore
            }
            Else{
                $rawObjects = $InputObject;
            }
            ForEach($element in @($rawObjects)){
                If($PSBoundParameters.ContainsKey('ExpandProperties') -and $PSBoundParameters['ExpandProperties']){
                    If($PSBoundParameters['ExpandProperties'] -eq '*'){
                        $selected_elements = $element | Select-Object * -ExcludeProperty $PSBoundParameters['ExcludedProperties'] -ErrorAction Ignore
                        #return object
                        $selected_elements | Format-PsObject
                    }
                    Else{
                        If(($element.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                            $selected_elements = New-Object -TypeName PSCustomObject
                            ForEach($key in @($PSBoundParameters['ExpandProperties'])){
                                $value = $element.GetPropertyByPath($key)
                                #Update psObject (escape values, convert to URI format, etc..)
                                If($null -ne $value){
                                    $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($value.GetType())
                                    #check if PsObject
                                    $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($value.GetType())
                                    if($isPsCustomObject -or $isPsObject){
                                        $value = $value | Select-Object * -ExcludeProperty $PSBoundParameters['ExcludedProperties'] -ErrorAction Ignore
                                    }
                                }
                                $value = $value | Format-PsObject
                                $selected_elements | Add-Member -type NoteProperty -name ($key.Split('.')[-1]) -value $value -Force
                            }
                            #return object
                            $selected_elements
                        }
                    }
                }
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}

