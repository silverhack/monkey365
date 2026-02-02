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

Function Update-MonkeyRule{
    <#
        .SYNOPSIS
        Update rule with displayName, description, level, etc..

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-MonkeyRule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True,HelpMessage="Rule object")]
        [Object]$InputObject,

        [parameter(Mandatory=$False, HelpMessage="Rule arguments")]
        [System.Array]$Arguments,

        [parameter(Mandatory=$False, HelpMessage="Rule displayName")]
        [System.String]$DisplayName,

        [parameter(Mandatory=$False, HelpMessage="Rule description")]
        [System.String]$Description,

        [parameter(Mandatory=$False, HelpMessage="Rule impact")]
        [System.String]$Impact,

        [parameter(Mandatory=$False, HelpMessage="Rule remediation")]
        [System.String]$Remediation,

        [parameter(Mandatory=$False, HelpMessage="Rule rationale")]
        [System.String]$Rationale,

        [parameter(Mandatory=$False, HelpMessage="Rule references")]
        [System.Array]$References,

        [parameter(Mandatory=$False, HelpMessage="Rule level")]
        [System.String]$Level,

        [parameter(Mandatory=$False, HelpMessage="Rule compliance")]
        [Object]$Compliance
    )
    Process{
        #Check for level
        If($PSBoundParameters.ContainsKey('Level') -and $PSBoundParameters['Level'] -match "info|low|medium|high|critical"){
            $InputObject | Add-Member -Type NoteProperty -name level -value $PSBoundParameters['Level'] -Force
        }
        #Check for displayName
        If($PSBoundParameters.ContainsKey('DisplayName') -and $PSBoundParameters['DisplayName']){
            $InputObject | Add-Member -Type NoteProperty -name displayName -value $PSBoundParameters['DisplayName'] -Force
        }
        #Check for Description
        If($PSBoundParameters.ContainsKey('Description') -and $PSBoundParameters['Description']){
            $InputObject | Add-Member -Type NoteProperty -name description -value $PSBoundParameters['Description'] -Force
        }
        #Check for Impact
        If($PSBoundParameters.ContainsKey('Impact') -and $PSBoundParameters['Impact']){
            $InputObject | Add-Member -Type NoteProperty -name impact -value $PSBoundParameters['Impact'] -Force
        }
        #Check for Remediation
        If($PSBoundParameters.ContainsKey('Remediation') -and $PSBoundParameters['Remediation']){
            $InputObject | Add-Member -Type NoteProperty -name remediation -value $PSBoundParameters['Remediation'] -Force
        }
        #Check for Rationale
        If($PSBoundParameters.ContainsKey('Rationale') -and $PSBoundParameters['Rationale']){
            $InputObject | Add-Member -Type NoteProperty -name rationale -value $PSBoundParameters['Rationale'] -Force
        }
        #Check for References
        If($PSBoundParameters.ContainsKey('References') -and $PSBoundParameters['References'].Count -gt 0){
            $_references = [System.Collections.Generic.List[System.String]]::new()
            ForEach($newReference in $PSBoundParameters['References'].GetEnumerator()){
                [void]$_references.Add($newReference.ToString())
            }
            $InputObject | Add-Member -Type NoteProperty -name references -value $_references -Force
        }
        #Check for Compliance
        If($PSBoundParameters.ContainsKey('Compliance') -and $PSBoundParameters['Compliance']){
            $InputObject | Add-Member -Type NoteProperty -name compliance -value $PSBoundParameters['Compliance'] -Force
        }
        #Check for Arguments
        If($PSBoundParameters.ContainsKey('Arguments') -and $PSBoundParameters['Arguments'].Count -gt 0){
            Try{
                $_tmpRule = $InputObject | ConvertTo-Json -Depth 50 -Compress
                For($i= 0;$i -lt $PSBoundParameters['Arguments'].Count;$i++){
                    $string_replace= ('(?<Item>_ARG_{0}_)' -f $i)
                    $_arg = $PSBoundParameters['Arguments'][$i];
                    If($_arg){
                        $_tmpRule = $_tmpRule -replace $string_replace,$_arg
                    }
                    Else{
                        $_tmpRule = $_tmpRule -replace $string_replace,""
                    }
                }
                #Create JSON rule
                $InputObject = $_tmpRule | ConvertFrom-Json
            }
            Catch{
                $name = $InputObject | Select-Object -ExpandProperty displayName -ErrorAction Ignore
                Write-Warning -Message ($Script:messages.InvalidRuleMessage -f $name)
                Write-Verbose $_.Exception
            }
        }
        #Return new object
        return $InputObject
    }
}

