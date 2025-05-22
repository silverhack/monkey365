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

Function New-HtmlTableFromObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlTableFromObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    Param (
        [parameter(Mandatory= $True, HelpMessage= "Table data")]
        [Object]$Data,

        [parameter(Mandatory= $false, HelpMessage= "Table class name")]
        [String[]]$ClassName,

        [parameter(Mandatory= $false, HelpMessage= "ID table")]
        [String]$Id,

        [parameter(Mandatory= $false, HelpMessage= "AsList table")]
        [Switch]$AsList,

        [parameter(Mandatory= $false, HelpMessage= "ShowModal button")]
        [Switch]$ShowModalButton,

        [parameter(Mandatory= $false, HelpMessage= "ShowGoTo button")]
        [Switch]$ShowGoToButton,

        [parameter(Mandatory= $false, HelpMessage= "Extended data")]
        [Object]$ExtendedData,

        [parameter(Mandatory= $false, HelpMessage= "Decorate data")]
        [System.Array]$Decorate,

        [parameter(Mandatory= $false, HelpMessage= "Emphasis data")]
        [System.Array]$Emphasis,

        [parameter(Mandatory= $false, HelpMessage= "Emphasis class")]
        [String[]]$EmphasisClass = 'cell-highlight',

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
    }
    Process{
        $formattedData = $Data | Format-PsObject
        If($null -ne $formattedData){
            #Check if AsList Table
            If($PSBoundParameters.ContainsKey('AsList') -and $PSBoundParameters['AsList'].IsPresent){
                #Convert to HTML table
                $outTable = $formattedData | Microsoft.PowerShell.Utility\ConvertTo-Html -As List -Fragment
                $outDataTable = $outTable -replace "<td><hr></td>", "<td><hr/></td><td><hr/></td>"
                $table = "<table><thead>`n{0}`n</thead>`n<tbody>`n{1}`n</tbody></table>" -f $outDataTable[1], ($outDataTable[2..($outDataTable.Count - 2)] -join "`n")
                #Decode table
                [xml]$xmlTable = [System.Net.WebUtility]::HtmlDecode($table)
                #Import table
                $newxmlTable = $TemplateObject.ImportNode($xmlTable.get_DocumentElement(), $True)
                #Set class
                [void]$newxmlTable.SetAttribute('class',"table monkey-table-vertical table-borderless no-footer");
                #Set Table mode
                [void]$newxmlTable.SetAttribute('type',"asList")
                #emphasis data
                If($PSBoundParameters.ContainsKey('Emphasis') -and $PSBoundParameters['Emphasis']){
                    Foreach($emphasisElement in $PSBoundParameters['Emphasis']){
                        #Find element
                        $element = $newxmlTable.SelectNodes(('tbody/tr[td="{0}:"]' -f $emphasisElement))
                        If($element){
                            ForEach($node in $element){
                                $node.LastChild.SetAttribute('class',$EmphasisClass)
                            }
                        }
                    }
                }
            }
            Else{
                $tmpTable = '<table>${formattedData}</table>'
                $outTable = $formattedData | Microsoft.PowerShell.Utility\ConvertTo-Html -As Table -Fragment
                $outDataTable = "<thead>`n{0}`n</thead>`n<tbody>`n{1}`n</tbody>" -f $outTable[2], ($outTable[3..($outTable.Count - 2)] -join "`n")
                $table = $tmpTable -replace '\${formattedData}', $outDataTable
                #Decode table
                [xml]$xmlTable = [System.Net.WebUtility]::HtmlDecode($table);
                #Import table
                $newxmlTable = $TemplateObject.ImportNode($xmlTable.get_DocumentElement(), $True)
                #Set class
                #[void]$newxmlTable.SetAttribute('class',"table monkey-table");
                [void]$newxmlTable.SetAttribute('class',"table monkey-table");
                #Set Table mode
                [void]$newxmlTable.SetAttribute('type',"Default")
                #Set Table style
                [void]$newxmlTable.SetAttribute('style',"width:100%;")
                #Check for disabled/enabled/notset elements
                $tds = $newxmlTable.SelectNodes("//td")
                foreach($td in @($tds)){
                    If($td.InnerText.ToLower() -eq 'disabled'){
                        #Create new A element
                        $spanProperties = @{
                            Name = "span";
                            Attributes = @{
                                class = "badge badge-warning badge-xl";
                            };
                            Text = $td.InnerText;
                            CreateTextNode = $True;
                            Template = $TemplateObject;
                        }
                        #Create span tag
                        $span = New-HtmlTag @spanProperties
                        If($span){
                            $td.InnerText = $null
                            [void]$td.AppendChild($span)
                        }
                    }
                    ElseIf($td.InnerText.ToLower() -eq 'enabled'){
                        #Create new A element
                        $spanProperties = @{
                            Name = "span";
                            Attributes = @{
                                class = "badge badge-success badge-xl";
                            };
                            Text = $td.InnerText;
                            CreateTextNode = $True;
                            Template = $TemplateObject;
                        }
                        #Create span tag
                        $span = New-HtmlTag @spanProperties
                        If($span){
                            $td.InnerText = $null
                            [void]$td.AppendChild($span)
                        }
                    }
                    ElseIf($td.InnerText.ToLower() -eq 'notset'){
                        #Create new A element
                        $spanProperties = @{
                            Name = "span";
                            Attributes = @{
                                class = "badge badge-disabled badge-xl";
                            };
                            Text = $td.InnerText;
                            CreateTextNode = $True;
                            Template = $TemplateObject;
                        }
                        #Create span tag
                        $span = New-HtmlTag @spanProperties
                        If($span){
                            $td.InnerText = $null
                            [void]$td.AppendChild($span)
                        }
                    }
                }
                #Decorate data
                If($PSBoundParameters.ContainsKey('Decorate') -and $PSBoundParameters['Decorate']){
                    Foreach($decorateOptions in $PSBoundParameters['Decorate']){
                        $itemName = $decorateOptions | Select-Object -ExpandProperty ItemName -ErrorAction Ignore
                        $itemValue = $decorateOptions | Select-Object -ExpandProperty ItemValue -ErrorAction Ignore
                        $itemClassName = $decorateOptions | Select-Object -ExpandProperty className -ErrorAction Ignore
                        #Find element
                        $element = $newxmlTable.SelectNodes(('//td[(count(//tr/th[.="{0}"]/preceding-sibling::*)+1)]' -f $itemName))
                        If($element){
                            ForEach($node in $element){
                                If($node.InnerText.ToString().ToLower() -eq $itemValue.ToString()){
                                    $node.LastChild.SetAttribute('class',$itemClassName)
                                }
                            }
                        }
                    }
                }
                #Add showmodal and goto buttons
                If($PSBoundParameters.ContainsKey('ExtendedData') -and $PSBoundParameters['ExtendedData'] -and (($PSBoundParameters.ContainsKey('ShowModalButton') -and $PSBoundParameters['ShowModalButton'].IsPresent) -or ($PSBoundParameters.ContainsKey('ShowGoToButton') -and $PSBoundParameters['ShowGoToButton'].IsPresent))){
                    Set-Variable -Name table -Value $newxmlTable -scope Global -Force
                    #Set actions column
                    $thead = $newxmlTable.SelectSingleNode("thead/tr")
                    #Add Actions column
                    $th = $TemplateObject.CreateElement("th")
                    $th.InnerText = "Actions"
                    [void]$thead.AppendChild($th)
                    #Iterate over body to add buttons
                    $tbody = $newxmlTable.SelectSingleNode("tbody")
                    For ($idx=0;$idx -lt $tbody.ChildNodes.Count; $idx++){
                        #Create Td object
                        $td = $TemplateObject.CreateElement("td")
                        Try{
                            If($idx -lt @($PSBoundParameters['ExtendedData']).Count){
                                $id = ("#{0}" -f $PSBoundParameters['ExtendedData'].Item($idx).id);
                            }
                            Else{
                                $id = $null;
                            }
                        }
                        Catch{
                            $id = $null
                        }
                        If($PSBoundParameters.ContainsKey('ShowModalButton') -and $PSBoundParameters['ShowModalButton'].IsPresent){
                            #Create I object
                            $iProperties = @{
                                Name = "i";
                                Attributes = @{
                                    class = "bi bi-eye";
                                };
                                Empty = $True;
                                Template = $TemplateObject;
                            }
                            #Create i tag
                            $i = New-HtmlTag @iProperties
                            #Create button
                            $buttonProperties = @{
                                Name = "button";
                                Attributes = @{
                                    class = 'btn btn-primary me-2';
                                    title = "showModal";
                                    type = 'button';
                                    "data-bs-target" = $Id;
                                    "data-bs-toggle" = "modal";
                                };
                                AppendObject = $i;
                                Template = $TemplateObject;
                            }
                            $showGotoObjButton = New-HtmlTag @buttonProperties
                            [void]$td.AppendChild($showGotoObjButton);
                        }
                        [void]$tbody.ChildNodes.Item($idx).LastChild.AppendChild($td)
                        #Close i tags
                        $i_tags = $tbody.ChildNodes.Item($idx).SelectNodes("//i")
                        $i_tags | ForEach-Object {$_.InnerText = [string]::Empty}
                    }
                }
            }
            #Check if Id
            If($PSBoundParameters.ContainsKey('Id') -and $PSBoundParameters['Id']){
                [void]$newxmlTable.SetAttribute('id',$PSBoundParameters['Id'])
            }
            Else{
                $tableId = ("MonkeyTable_{0}" -f [System.Guid]::NewGuid().Guid.Replace('-','').ToString());
                [void]$newxmlTable.SetAttribute('id',$tableId)
            }
            #Set Class name
            If($PSBoundParameters.ContainsKey('ClassName') -and $PSBoundParameters['ClassName']){
                $oldClass = $newxmlTable.table.class
                $_Class = [String]::Join(' ',$PSBoundParameters['ClassName']);
                $tableClass = ("{0} {1}" -f $oldClass,$_Class)
                [void]$newxmlTable.SetAttribute('class',$tableClass);
            }
            #Add table to main div
            #Create a root div element
            <#
            $divProperties = @{
                Name = "div";
                Attributes = @{
                    class = "monkey-datatable";
                };
                AppendObject = $newxmlTable;
                Template = $TemplateObject;
            }
            #Create div tag
            $rootDiv = New-HtmlTag @divProperties
            #>
            #return table
            $newxmlTable
        }
    }
    End{
    }
}
