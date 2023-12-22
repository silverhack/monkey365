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

Function Initialize-HtmlData{
    <#
        .SYNOPSIS

        Update psObject (escape values, convert to URI format, etc..)

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-HtmlData
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Object")]
        [Object]$InputObject
    )
    Process{
        #extendedData Generic List
        $extendedData = New-Object System.Collections.Generic.List[System.Object]
        try{
            $showModal = [System.Convert]::ToBoolean($InputObject.actions.showModalButton)
            $goTo = [System.Convert]::ToBoolean($InputObject.actions.showGoToButton)
            $expand = $InputObject.actions.objectData | Select-Object -ExpandProperty expand -ErrorAction Ignore
            $format = $InputObject.actions.objectData.format
        }
        catch{
            $showModal = $false
            $goTo = $false
            $expand = '*'
            $format = 'json'
        }
        try{
            #Formatting object
            If($null -ne $InputObject.affectedResources){
                $returnObject = $InputObject | ConvertTo-PsTableObject
                if($null -eq $returnObject){
                    #convert objects
                    $returnObject = $InputObject.affectedResources | Format-PsObject
                }
                else{
                    #Check if modal
                    if($showModal){
                        foreach($element in $InputObject.affectedResources){
                            $selected_elements = $null;
                            if($expand -eq '*'){
                                $selected_elements = $element | Select-Object * -ExcludeProperty Raw -ErrorAction Ignore
                            }
                            else{
                                try{
                                    $selected_elements = New-Object -TypeName PSCustomObject
                                    foreach($key in @($expand)){
                                        $value = $element.GetPropertyByPath($key)
                                        #Update psObject (escape values, convert to URI format, etc..)
                                        if($null -ne $value){
                                            $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($value.GetType())
                                            #check if PsObject
                                            $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($value.GetType())
                                            if($isPsCustomObject -or $isPsObject){
                                                $value = $value | Select-Object * -ExcludeProperty rawObject
                                            }
                                        }
                                        $value = $value | Format-PsObject
                                        $selected_elements | Add-Member -type NoteProperty -name ($key.Split('.')[-1]) -value $value -Force
                                    }
                                }
                                catch{
                                    Write-Error $_
                                    $selected_elements = $null;
                                }
                            }
                            if($null -ne $selected_elements){
                                if($format -eq "json"){
                                    $id = ("rawObject_{0}" -f [System.Guid]::NewGuid().Guid.Replace('-','').ToString())
                                }
                                else{
                                    $id = ("{0}" -f [System.Guid]::NewGuid().Guid.Replace('-','').ToString())
                                }
                                $new_obj = [psobject]@{
                                    raw_data = $selected_elements;
                                    format = $format;
                                    id = $id;
                                }
                                #Add to array
                                [void]$extendedData.Add($new_obj);
                            }
                        }
                    }
                }
            }
            #Update PsObject
            $InputObject | Add-Member -type NoteProperty -name data -value $returnObject -Force
            $InputObject | Add-Member -type NoteProperty -name extended_data -value $extendedData -Force
            ## Return the object but don't enumerate it
            $InputObject
        }
        catch{
            Write-Error $_
        }
    }
}