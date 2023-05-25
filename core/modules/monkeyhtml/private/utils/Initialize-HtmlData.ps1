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
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ParameterSetName='issue', position=0, ValueFromPipeline=$true, HelpMessage="Object")]
        [Object]$InputObject
    )
    Begin{
        #Nothing to do here
    }
    Process{
        #ReturnObject and extendedData Generic List
        $returnObject = New-Object System.Collections.Generic.List[System.Object]
        $extendedData = New-Object System.Collections.Generic.List[System.Object]
        #Formatting object
        If($null -ne $InputObject.affected_resources){
            #Check for limits
            if($null -ne $InputObject.actions.objectData.PsObject.Properties.Item('limit') -and $null -ne $InputObject.actions.objectData.limit){
                [int]$int_min_value = [int32]::MinValue;
                [bool]$integer = [int]::TryParse($InputObject.actions.objectData.limit, [ref]$int_min_value);
                if($integer){
                    $elements = $InputObject.affected_resources | Select-Object -First $InputObject.actions.objectData.limit
                }
                else{
                    Write-Verbose "Unable to limit objects"
                }
            }
            else{
                $elements = $InputObject.affected_resources
            }
            If($null -ne $InputObject.translate){
                ForEach($element in $elements){
                    $new_element = New-Object -TypeName PSCustomObject
                    ForEach($prop in $InputObject.translate.PsObject.Properties){
                        try{
                            $value = $element.GetPropertyByPath($prop.Name)
                            #Update psObject (escape values, convert to URI format, etc..)
                            $value = $value | Format-PsObject
                            if($value -is [System.Collections.IEnumerable] -and $value -isnot [string]){
                                $value = (@($value) -join ',')
                            }
                            $new_element | Add-Member -type NoteProperty -name $prop.Value -value $value
                        }
                        catch{
                            Write-Warning ("Error in {0}" -f $issue.id_suffix)
                            Write-Warning ($_.Exception)
                        }
                    }
                    #Add to array
                    [void]$returnObject.Add($new_element);
                    #Check if modal
                    if($null -ne $InputObject.actions.PsObject.Properties.Item('showModalButton') -and $InputObject.actions.showModalButton -eq $true){
                        if($null -ne $InputObject.actions.objectData.expand){
                            if($InputObject.actions.objectData.expand.Contains('*')){
                                $selected_elements = $element | Select-Object * -ErrorAction Ignore
                            }
                            else{
                                try{
                                    $selected_elements = New-Object -TypeName PSCustomObject
                                    foreach($key in @($InputObject.actions.objectData.expand)){
                                        $value = $element.GetPropertyByPath($key)
                                        #Update psObject (escape values, convert to URI format, etc..)
                                        $value = $value | Select-Object * -ExcludeProperty rawObject
                                        $value = $value | Format-PsObject
                                        $selected_elements | Add-Member -type NoteProperty -name $key -value $value -Force
                                    }
                                }
                                catch{
                                    Write-Error $_
                                    $selected_elements = $null;
                                }
                            }
                            if($null -ne $selected_elements){
                                if($InputObject.actions.objectData.format -eq "json"){
                                    $id = ("rawObject_{0}" -f [System.Guid]::NewGuid().Guid.Replace('-','').ToString())
                                }
                                else{
                                    $id = ("{0}" -f [System.Guid]::NewGuid().Guid.Replace('-','').ToString())
                                }
                                $new_obj = [psobject]@{
                                    raw_data = $selected_elements;
                                    format = $InputObject.actions.objectData.format;
                                    id = $id;
                                }
                                #Add to array
                                [void]$extendedData.Add($new_obj);
                            }
                        }
                    }
                    #End modal
                }
            }
            else{
                Write-Verbose ("Empty translate properties found on {0}" -f $InputObject.id_suffix)
                #convert objects
                $returnObject = $InputObject.affected_resources | Format-PsObject
            }
        }
        #Update PsObject
        $InputObject | Add-Member -type NoteProperty -name data -value $returnObject -Force
        $InputObject | Add-Member -type NoteProperty -name extended_data -value $extendedData -Force
        ## Return the object but don't enumerate it
        $InputObject
    }
    End{
        #Nothing to do here
    }
}