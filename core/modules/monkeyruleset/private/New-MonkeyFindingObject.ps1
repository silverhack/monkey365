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

Function New-MonkeyFindingObject {
<#
        .SYNOPSIS
		Create a new finding object

        .DESCRIPTION
		Create a new finding object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyFindingObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="issue object")]
        [Object]$InputObject,

        [parameter(Mandatory= $false, HelpMessage="affected objects")]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$AffectedObjects,

        [parameter(Mandatory= $false, HelpMessage="objects to check")]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$Resources,

        [Parameter(Mandatory=$false, HelpMessage="Set the output timestamp format as unix timestamps instead of iso format")]
        [Switch]$UnixTimestamp
    )
    Process{
        try{
            #Check level
            if($null -eq $InputObject.PsObject.Properties.Item('level')){
                $InputObject | Add-Member -Type NoteProperty -name level -value $null -Force
            }            
            #Add metadata
            $Metadata = $InputObject | Get-ObjectFromDataset -Metadata
            $InputObject | Add-Member -Type NoteProperty -name metadata -value $Metadata -Forc
            $InputObject | Add-Member -Type NoteProperty -name affectedResources -value $AffectedObjects -Force
            $InputObject | Add-Member -Type NoteProperty -name resources -value $Resources -Force
            #Format html and text output if exists
            If($PSBoundParameters.ContainsKey('AffectedObjects') -and $PSBoundParameters['AffectedObjects']){
                #Format HTML if exists
                Try{
                    $p = @{
                        Expressions = $InputObject.output.html.data.properties;
                        ExpandObject = $InputObject.output.html.data.expandObject ;
                    }
                    $dataOut = $PSBoundParameters['AffectedObjects'] | Format-DataFromExpression @p
                    #Add to object
                    $InputObject.output.html | Add-Member -Type NoteProperty -name out -value $dataOut -Force
                }
                Catch{
                    Write-Warning -Message ($Script:messages.UnableToFormatErrorMessage -f "HTML")
                    $InputObject.output.html | Add-Member -Type NoteProperty -name out -value $null -Force
                }
                #Format text if exists
                Try{
                    $p = @{
                        Expressions = $InputObject.output.text.data.properties;
                        ExpandObject = $InputObject.output.text.data.expandObject ;
                    }
                    $dataOut = $PSBoundParameters['AffectedObjects'] | Format-DataFromExpression @p
                    #Add to object
                    $InputObject.output.text | Add-Member -Type NoteProperty -name out -value $dataOut -Force
                }
                Catch{
                    Write-Warning -Message ($Script:messages.UnableToFormatErrorMessage -f "text")
                    $InputObject.output.text | Add-Member -Type NoteProperty -name out -value $null -Force
                }
            }
            Else{
                Set-StrictMode -Off
                $InputObject.output.html | Add-Member -Type NoteProperty -name out -value $null -Force
                $InputObject.output.text | Add-Member -Type NoteProperty -name out -value $null -Force
            }
            #Add timestamp
            if($PSBoundParameters.ContainsKey('UnixTimestamp') -and $PSBoundParameters['UnixTimestamp'].IsPresent){
                $timestamp = ([System.DateTime]::UtcNow).ToString("yyyy-MM-ddTHH:mm:ssK")
            }
            Else{
                $timestamp = ([System.DateTime]::Now.ToString('o'))
            }
            $InputObject | Add-Member -Type NoteProperty -name timestamp -value $timestamp -Force
            #Add StatusCode
            $InputObject | Add-Member -Type NoteProperty -name statusCode -value $null -Force
            #Add method to count resources
            $InputObject | Add-Member -Type ScriptMethod -Name affectedResourcesCount -Value {
                If($null -ne $this.affectedResources){
                    return @($this.affectedResources).Count
                }
                Else{
                    return 0
                }
            } -Force
            #Add method to count resources
            $InputObject | Add-Member -Type ScriptMethod -Name resourcesCount -Value {
                If($null -ne $this.resources){
                    return @($this.resources).Count
                }
                Else{
                    return 0
                }
            } -Force
            #Add method to generate id suffix numbers
            $InputObject | Add-Member -Type ScriptMethod -Name getNewIdSuffix -Value {
                If($null -ne $this.idSuffix.Replace(' ','_')){
                    $guid = [System.Guid]::NewGuid().ToString('N')
                    return ("{0}_{1}" -f $this.idSuffix, $guid)
                }
            } -Force
            return $InputObject
        }
        catch{
            Write-Verbose $_.Exception.Message
        }
    }
}