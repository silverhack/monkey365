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
        [Object]$affectedObjects,

        [parameter(Mandatory= $false, HelpMessage="objects to check")]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$Resources
    )
    Process{
        try{
            #Set new obj
            $tmp_object = [ordered]@{}
            foreach($elem in $InputObject.Psobject.Properties){
                [void]$tmp_object.Add($elem.Name,$elem.Value)
            }
            $InputObject = New-Object -TypeName PSCustomObject -Property $tmp_object
            #Check level
            if($null -eq $InputObject.PsObject.Properties.Item('level')){
                $InputObject | Add-Member -Type NoteProperty -name level -value $null -Force
            }
            $InputObject | Add-Member -Type NoteProperty -name affectedResources -value $affectedObjects -Force
            $InputObject | Add-Member -Type NoteProperty -name resources -value $Resources -Force
            #Add method to count resources
            $InputObject | Add-Member -Type ScriptMethod -Name affectedResourcesCount -Value {
                if($null -ne $this.affectedResources){
                    return @($this.affectedResources).Count
                }
                else{
                    return 0
                }
            } -Force
            #Add method to count resources
            $InputObject | Add-Member -Type ScriptMethod -Name resourcesCount -Value {
                if($null -ne $this.resources){
                    return @($this.resources).Count
                }
                else{
                    return 0
                }
            } -Force
            #Add method to generate id suffix numbers
            $InputObject | Add-Member -Type ScriptMethod -Name getNewIdSuffix -Value {
                if($null -ne $this.idSuffix.Replace(' ','_')){
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