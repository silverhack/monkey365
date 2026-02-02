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

Function New-FindingCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-FindingCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage= "Template")]
        [Object]$FindingObject,

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
        Try{
            Foreach($findingObj in @($PSBoundParameters['FindingObject'])){
                Write-Verbose ($Script:messages.NewCardMessage -f $findingObj.title)
                If($findingObj.statusCode.ToLower() -eq "manual" -or $findingObj.statusCode.ToLower() -eq "pass"){
                    $bodyObject = [xml] '<div class="row monkey-finding-row"></div>'
                }
                Else{
                    $bodyObject = [xml] '<div class="row"></div>'
                }
                #Import node
                $bodyObject = $TemplateObject.ImportNode($bodyObject.DocumentElement,$true);
                #set Array
                $sections = [System.Collections.Generic.List[System.Management.Automation.PsObject]]::new()
                #Create new card
                $p = @{
                    ClassName = "monkey-finding-card","shadow-sm";
                    Header = $findingObj.displayName;
                    HeaderClass = "monkey-finding-header";
                    Id = ("FindingCard{0}" -f [System.Guid]::NewGuid().Guid.ToString().Replace('-',''))
                    Collapsible = $True;
                    Template = $TemplateObject;
                }
                $findingCard = New-HtmlCard @p
                #Get card header, body and footer
                $cardHeader = $findingCard.SelectSingleNode('//div[contains(@class,"card-header")]')
                $cardBody = $findingCard.SelectSingleNode('//div[contains(@class,"card-body")]')
                #Get icon
                $class = $findingObj.level | Get-IconFromLevel
                #Get I object
                $iProperties = @{
                    Name = "i";
                    ClassName = $class;
                    Empty = $True;
                    Template = $TemplateObject;
                }
                #Create element
                $iconHeader = New-HtmlTag @iProperties
                [void]$cardHeader.PrependChild($iconHeader);
                #Get finding card info
                $findingCardInfo = $findingObj | Get-HTMLFindingCardInfo -Template $TemplateObject
                If($findingCardInfo){
                    #Add to array
                    $sectionObj = [PsCustomObject]@{
                        name = "Info";
                        xml = $findingCardInfo;
                    }
                    [void]$sections.Add($sectionObj);
                }
                If($null -ne $findingObj.psobject.properties.Item('description') -and $null -ne $findingObj.description -and $findingObj.description.Length -gt 0){
                    $p = @{
                        Name = "Description";
                        Content = $findingObj.description;
                        Template = $TemplateObject;
                    }
                    $output = Get-HTMLCardContent @p
                }
                Else{
                    $p = @{
                        Name = "Description";
                        Content = 'No description available.';
                        Template = $TemplateObject;
                    }
                    $output = Get-HTMLCardContent @p
                }
                #Add to array
                $sectionObj = [PsCustomObject]@{
                    name = "Description";
                    xml = $output;
                }
                [void]$sections.Add($sectionObj);
                #Get rationale
                If($null -ne $findingObj.psobject.properties.Item('rationale') -and $null -ne $findingObj.rationale -and $findingObj.rationale.Length -gt 0){
                    $p = @{
                        Name = "Rationale";
                        Content = $findingObj.rationale;
                        Template = $TemplateObject;
                    }
                    $output = Get-HTMLCardContent @p
                    #Add to array
                    $sectionObj = [PsCustomObject]@{
                        name = "Rationale";
                        xml = $output;
                    }
                    [void]$sections.Add($sectionObj);
                }
                #Get impact
                If($null -ne $findingObj.psobject.properties.Item('impact') -and $null -ne $findingObj.impact -and $findingObj.impact.Length -gt 0){
                    $p = @{
                        Name = "Impact";
                        Content = $findingObj.impact;
                        Template = $TemplateObject;
                    }
                    $output = Get-HTMLCardContent @p
                    #Add to array
                    $sectionObj = [PsCustomObject]@{
                        name = "Impact";
                        xml = $output;
                    }
                    [void]$sections.Add($sectionObj);
                }
                #Get remediation
                Try{
                    If($null -ne $findingObj.remediation.text -and $findingObj.remediation.text.Length -gt 0){
                        $p = @{
                            Name = "Remediation";
                            Content = $findingObj.remediation.text;
                            Template = $TemplateObject;
                        }
                        $output = Get-HTMLCardContent @p
                        #Add to array
                        $sectionObj = [PsCustomObject]@{
                            name = "Remediation";
                            xml = $output;
                        }
                        [void]$sections.Add($sectionObj);
                    }
                }
                Catch{
                    Write-Warning ($Script:messages.UnableToGetProperty -f $findingObj.title)
                    Write-Error $_.Exception
                }
                #Get references
                If($null -ne $findingObj.psobject.properties.Item('references') -and $null -ne $findingObj.references -and @($findingObj.references).Count -gt 0){
                    $p = @{
                        Name = "References";
                        Content = $findingObj.references;
                        Template = $TemplateObject;
                    }
                    $output = Get-HTMLCardReference @p
                    #Add to array
                    $sectionObj = [PsCustomObject]@{
                        name = "References";
                        xml = $output;
                    }
                    [void]$sections.Add($sectionObj);
                }
                <#
                #Get compliance
                If($null -ne $findingObj.psobject.properties.Item('compliance') -and $null -ne $findingObj.compliance){
                    $p = @{
                        Name = "Compliance";
                        Content = $findingObj.compliance;
                        Template = $TemplateObject;
                    }
                    $output = Get-HTMLCardCompliance @p
                    #Add to array
                    $sectionObj = [PsCustomObject]@{
                        name = "Compliance";
                        xml = $output;
                    }
                    [void]$sections.Add($sectionObj);
                }
                #>
                #Fill card
                foreach($section in $sections){
                    Write-Verbose ($Script:messages.AppendElementMessageInfo -f $section.name, $findingObj.displayName);
                    [void]$bodyObject.AppendChild($section.xml);
                }
                #Add body object to card body
                If($findingObj.statusCode.ToLower() -in @('pass','manual')){
                    #Add to body
                    [void]$cardBody.AppendChild($bodyObject);
                }
                Else{
                    #Get Tab
                    $p = @{
                        Id = $findingObj.idSuffix;
                        Default = $True;
                        Template = $TemplateObject;
                    }
                    $tab = New-HTMLTab @p
                    #Get active tab pane
                    $_div = $tab.SelectSingleNode('//div[contains(@class,"show active")]')
                    If($null -ne $_div){
                        [void]$_div.AppendChild($bodyObject);
                    }
                    #Get tab pane
                    $_div = $tab.SelectSingleNode('//div[@class="tab-pane"]')
                    If($null -ne $_div){
                        $outData = $findingObj.output.html.out;
                        If($null -ne $outData){
                            $TableOption = $findingObj.output.html.table;
                            $extraFormat = $findingObj.output.html.decorate;
                            $extendedData = $findingObj.output.html.extendedData;
                            $emphasis = $findingObj.output.html.emphasis;
                            #Get showmodal and showgoto button
                            Try{
                                $out = $null;
                                [void][bool]::TryParse($findingObj.output.html.actions.showModalButton,[ref]$out);
                                $showModalButton = $out
                                $out = $null;
                                [void][bool]::TryParse($findingObj.output.html.actions.showGoToButton,[ref]$null)
                                $showGoToButton = $out
                            }
                            Catch{
                                $showModalButton = $false
                                $showGoToButton = $false
                            }
                            $p = @{
                                Data = $findingObj.output.html.out;
                                Template = $TemplateObject;
                                ShowModalButton = $showModalButton;
                                ShowGoToButton = $showGoToButton;
                            }
                            If($null -ne $TableOption -and $TableOption -ne "default"){
                                [void]$p.Add('AsList',$True);
                            }
                            If($null -ne $extraFormat -and @($extraFormat).Count -gt 0){
                                [void]$p.Add('Decorate',@($extraFormat))
                            }
                            If($null -ne $extendedData -and @($extendedData).Count -gt 0){
                                [void]$p.Add('ExtendedData',$extendedData);
                            }
                            If($null -ne $emphasis -and @($emphasis).Count -gt 0){
                                [void]$p.Add('Emphasis',$emphasis);
                            }
                            #Table goes here
                            $myTable = New-HtmlTableFromObject @p
                            [void]$_div.AppendChild($myTable);
                        }
                        Else{
                            Write-Warning ($Scripts:messages.EmptySectionMessage -f "data",$findingObj.title);
                        }
                    }
                    #Add to body
                    [void]$cardBody.AppendChild($tab);
                }
                $findingCard
            }
        }
        Catch{
            Write-Warning ($Script:messages.CardErrorMessage -f "Finding card", $findingObj.title);
            Write-Error $_.Exception
        }
    }
    End{
        #Nothing to do here
    }
}
