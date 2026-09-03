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

function New-HTMLTab{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HTMLTab
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(Mandatory= $true, ParameterSetName = 'NewTab', HelpMessage= "Tabs name")]
        [String[]]$Tabs,

        [parameter(Mandatory= $false, HelpMessage= "Class name")]
        [String[]]$ClassName,

        [parameter(Mandatory= $false, HelpMessage= "UL extra class name")]
        [String[]]$UlClassName,

        [parameter(Mandatory= $false, HelpMessage= "Li extra class name")]
        [String[]]$LiClassName,

        [parameter(Mandatory= $false, HelpMessage= "Tab-pane extra class name")]
        [String[]]$TabPaneClassName,

        [parameter(Mandatory= $false, HelpMessage= "Tab-content extra class name")]
        [String[]]$TabContentClassName,

        [parameter(Mandatory= $false, HelpMessage= "ID card")]
        [String]$Id,

        [parameter(Mandatory= $false, ParameterSetName = 'Default', HelpMessage= "Default tab")]
        [Switch]$Default,

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
        If($Default.IsPresent){
            #base object
            $defaultTabObject = [xml] '<div class="tab"><ul class="nav nav-tabs" role="tablist"><li class="nav-item" role="presentation"><a class="nav-link active" href="#tab-1" data-bs-toggle="tab" role="tab" aria-selected="true">Finding Details</a></li><li class="nav-item" role="presentation"><a class="nav-link" href="#tab-2" data-bs-toggle="tab" role="tab" aria-selected="false" tabindex="-1">Affected Resources</a></li></ul><div class="tab-content"><div class="tab-pane show active" id="tab-1" role="tabpanel"></div><div class="tab-pane" id="tab-2" role="tabpanel"></div></div></div>'
            #Get ID if present
            If($PSBoundParameters.ContainsKey('Id') -and $PSBoundParameters['Id']){
                $activeNavLinkId = ("{0}_{1}" -f $PSBoundParameters['Id'],[System.Guid]::NewGuid().Guid.Replace('-',''))
                $navLinkId = ("{0}_{1}" -f $PSBoundParameters['Id'],[System.Guid]::NewGuid().Guid.Replace('-',''))
            }
            Else{
                $activeNavLinkId = [System.Guid]::NewGuid().Guid.Replace('-','')
                $navLinkId = [System.Guid]::NewGuid().Guid.Replace('-','')
            }
            #Import node
            $defaultTabObject = $TemplateObject.ImportNode($defaultTabObject.DocumentElement,$true);
            #Get active nav-link
            $navLink = $defaultTabObject.SelectSingleNode('//a[contains(@class,"active")]')
            $divNavLink = $defaultTabObject.SelectSingleNode('//div[contains(@class,"active")]')
            If($navLink -and $divNavLink){
                [void]$navLink.SetAttribute('href',("#{0}" -f $activeNavLinkId));
                [void]$divNavLink.SetAttribute('id',$activeNavLinkId);
            }
            #Get nav-link
            $navLink = $defaultTabObject.SelectSingleNode('//a[@class="nav-link"]')
            $divNavLink = $defaultTabObject.SelectSingleNode('//div[@class="tab-pane"]')
            If($navLink -and $divNavLink){
                [void]$navLink.SetAttribute('href',("#{0}" -f $navLinkId));
                [void]$divNavLink.SetAttribute('id',$navLinkId);
            }
        }
        Else{
            #main tab
            $defaultTabObject = [xml] '<div class="tab"></div>'
            #Import node
            $defaultTabObject = $TemplateObject.ImportNode($defaultTabObject.DocumentElement,$true);
            #UL object
            $UL = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'ul', $TemplateObject.NamespaceURI);
            [void]$UL.SetAttribute('role',"tablist")
            [void]$UL.SetAttribute('class',"nav nav-tabs")
            If($PSBoundParameters.ContainsKey('UlClassName') -and $PSBoundParameters['UlClassName']){
                $_Class = [String]::Join(' ',$UlClassName);
                $_Class = ("nav nav-tabs {0}" -f $_Class)
                [void]$UL.SetAttribute('class',$_Class)
            }
            #LI object
            $LI = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'li', $TemplateObject.NamespaceURI);
            [void]$LI.SetAttribute('role',"presentation")
            [void]$LI.SetAttribute('class',"nav-item")
            If($PSBoundParameters.ContainsKey('LiClassName') -and $PSBoundParameters['LiClassName']){
                $_Class = [String]::Join(' ',$LiClassName);
                $_Class = ("nav-item {0}" -f $_Class)
                [void]$LI.SetAttribute('class',$_Class)
            }
            #tab-content object
            $DivContent = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'div', $TemplateObject.NamespaceURI);
            [void]$DivContent.SetAttribute('class',"tab-content")
            If($PSBoundParameters.ContainsKey('TabContentClassName') -and $PSBoundParameters['TabContentClassName']){
                $_Class = [String]::Join(' ',$TabContentClassName);
                $_Class = ("tab-content {0}" -f $_Class)
                [void]$DivContent.SetAttribute('class',$_Class)
            }
            #tab-pane object
            $DivTabPane = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'div', $TemplateObject.NamespaceURI);
            [void]$DivTabPane.SetAttribute('role',"tabpanel")
            [void]$DivTabPane.SetAttribute('class',"tab-pane")
            If($PSBoundParameters.ContainsKey('TabPaneClassName') -and $PSBoundParameters['TabPaneClassName']){
                $_Class = [String]::Join(' ',$TabPaneClassName);
                $_Class = ("tab-pane {0}" -f $_Class)
                [void]$DivTabPane.SetAttribute('class',$_Class)
            }
            #Get ID if present
            If($PSBoundParameters.ContainsKey('Id') -and $PSBoundParameters['Id']){
                $navLinkId = ("{0}_{1}" -f $PSBoundParameters['Id'],[System.Guid]::NewGuid().Guid.Replace('-',''))
            }
            Else{
                $navLinkId = [System.Guid]::NewGuid().Guid.Replace('-','')
            }
            $count = 0;
            #Iterate over each element
            Foreach($tab in $PSBoundParameters['Tabs']){
                $linkId = $navLinkId+1
                If($count -eq 0){
                    #Create new A active element
                    $aProperties = @{
                        Name = "a";
                        Attributes = @{
                            Class = "nav-link active";
                            "data-bs-toggle" = "tab";
                            "role" = "tab";
                            "aria-selected" = "true";
                            href = ("#{0}" -f $linkId);
                        };
                        Text = $tab;
                        CreateTextNode = $True;
                        Template = $TemplateObject;
                    }
                }
                Else{
                    #Create new A element
                    $aProperties = @{
                        Name = "a";
                        Attributes = @{
                            Class = "nav-link";
                            "data-bs-toggle" = "tab";
                            "role" = "tab";
                            "aria-selected" = "true";
                            href = ("#{0}" -f $linkId);
                        };
                        Text = $tab;
                        CreateTextNode = $True;
                        Template = $TemplateObject;
                    }
                }
                #Create element
                $aLink = New-HtmlTag @aProperties
                #Clone Li object
                $liObject = $LI.Clone()
                #Append a link
                [void]$liObject.AppendChild($aLink);
                #Add to ul object
                [void]$UL.AppendChild($liObject);
                #Clone DivTabPane
                $_DivTabPane = $DivTabPane.Clone()
                #Set id
                [void]$_DivTabPane.SetAttribute('id',$linkId);
                If($count -eq 0){
                    $_class = $_DivTabPane.class
                    [void]$_DivTabPane.SetAttribute('class',("{0} active show" -f $_Class));
                }
                #Add to tab content
                [void]$DivContent.AppendChild($_DivTabPane);
                #Increment count
                $count+=1
            }
            #Add ul and content to tab
            [void]$defaultTabObject.AppendChild($UL)
            [void]$defaultTabObject.AppendChild($DivContent)
            #Set Class name
            If($ClassName){
                $_tab = $defaultTabObject.SelectSingleNode('//div[@class="tab"]')
                $_Class = [String]::Join(' ',$ClassName);
                $div_class = ("card {0}" -f $_Class)
                [void]$_tab.SetAttribute('class',$div_class)
            }
        }
    }
    End{
        return $defaultTabObject
    }
}
