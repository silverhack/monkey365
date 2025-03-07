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

Function Get-ObjectPropertyByPath {
    <#
        .SYNOPSIS
		Get object property by path

        .DESCRIPTION
		Get object property by path

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ObjectPropertyByPath
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, HelpMessage="PsObject")]
        [Object]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage="Object property")]
        [String]$Property
    )
    Process{
        #check if PsObject
        $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($InputObject.GetType())
        #check if PsObject
        $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($InputObject.GetType())
        If($isPsCustomObject -or $isPsObject){
            If($PSBoundParameters.ContainsKey('Property') -and $PSBoundParameters['Property']){
                If($PSBoundParameters['Property'].Trim().ToString().Contains('.')){
                    #Get query object
                    If(($InputObject.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                        $InputObject.GetPropertyByPath($PSBoundParameters['Property'])
                    }
                    Else{
                        Write-Warning -Message $Script:messages.MethodNotFound
                        return
                    }
                }
                Else{
                    $InputObject | Select-Object -ExpandProperty $PSBoundParameters['Property'] -ErrorAction Ignore
                }
            }
            Else{
                return $null
            }
        }
        Else{
            Write-Warning -Message $Script:messages.InvalidPsObject
        }
    }
}

