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

Function New-PsHtmlObject{
    <#
        .SYNOPSIS

        Create a new psObject with properties to format HTML table, select properties to JSON, etc..

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-PsHtmlObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Object")]
        [Object]$InputObject
    )
    Begin{
        $Object = $null;
    }
    Process{
        #check If affected resources is empty
        if($null -ne $InputObject.Psobject.Properties.Item('affectedResources') -and $null -ne $InputObject.affectedResources){
            try{
                if($null -ne (Get-Variable -Name dtables -ErrorAction Ignore)){
                    if($null -ne $InputObject.PsObject.Properties.Item('idSuffix') -and $null -ne $InputObject.idSuffix){
                        $table_formatting = $dtables | Select-Object -ExpandProperty $InputObject.idSuffix -ErrorAction Ignore
                        if($table_formatting){
                            #Convert to newObject
                            $ht = [ordered]@{}
                            foreach($elem in $table_formatting.PsObject.Properties){
                                [void]$ht.Add($elem.Name, $elem.Value)
                            }
                            #ConvertToPsObject
                            $Object = New-Object PSObject -Property $ht
                        }
                        else{
                            $translate = [ordered]@{
                                table = "Normal";
                                translate = $null;
                                objectData = @{
                                    limit = 2000;
                                    expand = @('*');
                                    format = "json";
                                };
                                showGoToButton = $true;
                                showModalButton = $true;
                            }
                            #ConvertToPsObject
                            $Object = New-Object PSObject -Property $translate
                        }
                        #Add idSuffix
                        $Object | Add-Member -type NoteProperty -name idSuffix -value $InputObject.idSuffix -Force
                    }
                    else{
                        $translate = [ordered]@{
                            table = "Normal";
                            translate = $null;
                            objectData = @{
                                limit = 2000;
                                expand = @('*');
                                format = "json";
                            };
                            showGoToButton = $true;
                            showModalButton = $true;
                        }
                        #ConvertToPsObject
                        $Object = New-Object PSObject -Property $translate
                        #Add idSuffix
                        $Object | Add-Member -type NoteProperty -name idSuffix -value $null -Force
                    }
                }
                else{
                    $translate = [ordered]@{
                        table = "Normal";
                        translate = $null;
                        objectData = @{
                            limit = 2000;
                            expand = @('*');
                            format = "json";
                        };
                        showGoToButton = $true;
                        showModalButton = $true;
                    }
                    #ConvertToPsObject
                    $Object = New-Object PSObject -Property $translate
                    #Add idSuffix
                    $Object | Add-Member -type NoteProperty -name idSuffix -value $InputObject.idSuffix -Force
                }
                #Add raw_data
                if($null -ne $Object -and $null -ne $InputObject.Psobject.Properties.Item('affectedResources')){
                    $Object | Add-Member -type NoteProperty -name affectedResources -value $InputObject.affectedResources -Force
                }
                else{
                    $Object | Add-Member -type NoteProperty -name affectedResources -value $null -Force
                }
                if($null -ne $Object -and $null -eq $Object.psobject.Properties.Item('translate')){
                    $Object | Add-Member -type NoteProperty -name translate -value $null -Force
                }
                #Add expand for nested tables
                if($null -ne $Object -and $null -eq $Object.psobject.Properties.Item('expand')){
                    $Object | Add-Member -type NoteProperty -name expand -value $null -Force
                }
                #Check if action should be added to the table
                if($null -ne $Object -and ($null -ne $Object.psobject.Properties.Item('actions') -and $null -ne $Object.actions.psobject.Properties.Item('objectData'))){
                    If($null -ne $Object.actions.objectData.psobject.Properties.Item('expand') -and $null -eq $Object.actions.objectData.expand){
                        $Object.actions.objectData.expand = "{*}";
                    }
                    If($null -ne $Object.actions.objectData.psobject.Properties.Item('format') -and $null -eq $Object.actions.objectData.format){
                        $Object.actions.objectData.format = "json";
                    }
                    If($null -eq $Object.actions.objectData.psobject.Properties.Item('expand')){
                        $Object.actions.objectData | Add-Member -type NoteProperty -name expand -value "{*}" -Force
                    }
                }
                else{
                    $actions = [ordered]@{
                        objectData = @{
                            limit = 2000;
                            expand = @('*');
                            format = "json";
                        };
                        showGoToButton = $null;
                        showModalButton = $null;
                    }
                    $Object | Add-Member -type NoteProperty -name actions -value $actions -Force
                }
                #Add issue name
                if($null -ne $InputObject.PsObject.Properties.Item('displayName')){
                    $Object | Add-Member -type NoteProperty -name displayName -value $InputObject.displayName -Force
                }
                else{
                    $Object | Add-Member -type NoteProperty -name displayName -value "Unknown" -Force
                }
                #return Object
                $Object | Initialize-HtmlData
            }
            catch{
                Write-Verbose $_
            }
        }
    }
    End{
        #Nothing to do here
    }
}
