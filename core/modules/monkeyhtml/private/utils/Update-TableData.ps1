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

Function Update-TableData{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-TableData
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [Object]$issue
        )
    Begin{
        $properties = $returnObject = $objectsToExpand = $selected_elements = $null;
        $format = "json";
        if($null -ne (Get-Variable -Name dtables -ErrorAction Ignore)){
            $data = $dtables | Select-Object -ExpandProperty $issue.id_suffix -ErrorAction Ignore
            if($null -ne $data){
                $data | Add-Member -type NoteProperty -name raw_data -value $issue.affected_resources -Force
                if($null -ne $data.psobject.Properties.Item('translate')){
                    $properties = $data.translate.psobject.Properties
                    #Check if action should be added to the table
                    if($null -ne $data.psobject.Properties.Item('actions') -and $null -ne $data.actions.psobject.Properties.Item('objectData')){
                        if($null -ne $data.actions.objectData.psobject.Properties.Item('expand')){
                            $objectsToExpand = $data.actions.objectData.expand;
                        }
                    }
                    #Check if format is present
                    if($null -ne $data.psobject.Properties.Item('actions') -and $null -ne $data.actions.psobject.Properties.Item('objectData')){
                        if($null -ne $data.actions.objectData.psobject.Properties.Item('format')){
                            $format = $data.actions.objectData.format
                        }
                    }
                }
            }
            else{
                $data = [pscustomobject]@{
                    table = 'Normal';
                    raw_data = $issue.affected_resources;
                }
                #Set properties to null
                $properties = $null
            }
        }
        else{
            $data = [pscustomobject]@{
                table = 'Normal';
                raw_data = $issue.affected_resources;
            }
            #Set properties to null
            $properties = $null
        }
    }
    Process{
        if($properties){
            $returnObject = @()
            $modal_objects = @()
            try{
                foreach($element in $issue.affected_resources){
                    $new_element = New-Object -TypeName PSCustomObject
                    foreach($prop in $properties){
                        $value = $element.GetPropertyByPath($prop.Name)
                        #Update psObject (escape values, convert to URI format, etc..)
                        $value = $value | Format-PsObject
                        if($value -is [System.Collections.IEnumerable] -and $value -isnot [string]){
                            $value = (@($value) -join ',')
                        }
                        $new_element | Add-Member -type NoteProperty -name $prop.Value -value $value
                    }
                    #Check if modal
                    if($null -ne $objectsToExpand){
                        if($objectsToExpand.Contains('*')){
                            $selected_elements = $element | Select-Object $objectsToExpand -ErrorAction Ignore
                        }
                        else{
                            $selected_elements = New-Object -TypeName PSCustomObject
                            foreach($key in $objectsToExpand.GetEnumerator()){
                                $value = $element.GetPropertyByPath($key)
                                #Update psObject (escape values, convert to URI format, etc..)
                                $value = $value | Format-PsObject
                                $selected_elements | Add-Member -type NoteProperty -name $key -value $value -Force
                            }
                        }
                        #Write-Host ($selected_elements | Out-String)
                        if($format -eq "json"){
                            $id = ("rawObject_{0}" -f [System.Guid]::NewGuid().Guid.Replace('-','').ToString())
                        }
                        else{
                            $id = ("{0}" -f [System.Guid]::NewGuid().Guid.Replace('-','').ToString())
                        }
                        if($null -ne $selected_elements){
                            $new_obj = [psobject]@{
                                raw_data = $selected_elements;
                                format = $format;
                                id = $id;
                            }
                            $modal_objects+=$new_obj;
                        }
                    }
                    $returnObject+=$new_element
                }
            }
            catch{
                Write-Warning ("Error in {0}" -f $element.GetType())
                Write-Verbose $_
                Write-Debug $_.Exception.StackTrace
            }
        }
        else{
            #convert objects
            $value = $issue.affected_resources | Format-PsObject
            $returnObject = $value
            $modal_objects = @()
        }
    }
    End{
        if($returnObject){
            $data | Add-Member -type NoteProperty -name data -value $returnObject -Force
            #Add modal objects
            $data | Add-Member -type NoteProperty -name extended_data -value $modal_objects -Force
            return $data
        }
        else{
            Write-Warning ($script:messages.unableToProcessInputObject -f $issue.Name)
            return $null
        }
    }
}
