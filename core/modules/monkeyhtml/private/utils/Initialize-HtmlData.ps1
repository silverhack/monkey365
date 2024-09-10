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
        Try{
            If($null -ne $InputObject.PsObject.Properties.Item('affectedResources')){
                #Set generic list
                $extendedData = [System.Collections.Generic.List[System.Object]]::new();
                [int]$intMinValue = [int32]::MinValue;
                Try{
                    [bool]$limit = [int]::TryParse($InputObject.output.html.actions.objectData.limit, [ref]$intMinValue);
                    If($limit){
                        $InputObject.output.html.out = $InputObject.output.html.out | Select-Object -First $InputObject.output.html.actions.objectData.limit -ErrorAction Ignore
                        $affectedResources = $InputObject.affectedResources | Select-Object -First $InputObject.output.html.actions.objectData.limit -ErrorAction Ignore
                    }
                    Else{
                        $affectedResources = $InputObject.affectedResources;
                    }
                    $showModal = [System.Convert]::ToBoolean($InputObject.output.html.actions.showModalButton);
                    $goTo = [System.Convert]::ToBoolean($InputObject.output.html.actions.showGoToButton);
                    $expand = $InputObject.output.html.actions.objectData.expand;
                    $expandObject = $InputObject.output.html.data.expandObject;
                    #Get table output
                    $returnObject = $InputObject.output.html.out;
                }
                Catch{
                    $showModal = $false
                    $goTo = $false
                    $expand = '*'
                    $expandObject = $null
                    $returnObject = $null;
                    $affectedResources = $null;
                }
                #Check if modal
                If($showModal -and $null -ne $affectedResources){
                    $p = @{
                        ExpandObject = $expandObject;
                        ExcludedProperties = @("Raw","RawData","raw_data","rawPolicy","rawObject");
                        ExpandProperties = $expand;
                    }
                    $objs = $affectedResources | Resize-PsObject @p
                    Foreach($obj in @($objs)){
                        $id = ("rawObject_{0}" -f [System.Guid]::NewGuid().Guid.Replace('-','').ToString())
                        $new_obj = [psobject]@{
                            raw_data = $obj;
                            format = "json";
                            id = $id;
                        }
                        #Add to array
                        [void]$extendedData.Add($new_obj);
                    }
                }
                #Append psObject
                $InputObject.output.html | Add-Member -type NoteProperty -name extendedData -value $extendedData -Force
                #Format out
                $InputObject.output.html.out = $InputObject.output.html.out | Format-PsObject
                ## Return the object but don't enumerate it
                $InputObject
            }
            Else{
                Write-Warning "Property not found"
            }
        }
        Catch{
            Write-Warning $_.Exception
        }
    }
}