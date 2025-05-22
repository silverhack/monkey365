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

function New-SideBar{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-SideBar
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Matched items')]
        [Object]$InputObject,

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
        #Create NavBar
        $sidebar = $TemplateObject.CreateNode(
            [System.Xml.XmlNodeType]::Element,
            $TemplateObject.Prefix,
            "div",
            $TemplateObject.NamespaceURI
        );
        #Set attributes
        [void]$sidebar.SetAttribute("class","sidebar")
        [void]$sidebar.SetAttribute("id","sidebar")
        #$sidebar = [xml] '<div class="sidebar" id="sidebar"></div>'
        #Set header
        $DivElement = @{
            Name = 'div';
            ClassName = 'header';
            Template = $TemplateObject;
        }
        #Create div element
        $DivHeaderTag = New-HtmlTag @DivElement
        #Set A tag
        $a_attributes = @{
            href = "javascript:show('monkey-main-dashboard')";
            class = 'sidebar-brand';
        }
        $a_element = @{
            Name = 'a';
            Attributes = $a_attributes;
            Template = $TemplateObject;
        }
        #Create a element and combine with img and span tags
        $a_href = New-HtmlTag @a_element
        #Create Monkey365 IMG
        If($Script:mode -eq 'cdn'){
            $baseUrl = ("{0}/{1}" -f $Script:Repository,'assets/inc-monkey/logo/MonkeyLogo.png');
            $_iconPath = Convert-UrlToJsDelivr -Url $baseUrl -Latest
        }
        Else{
            $_iconPath = ("{0}/{1}" -f $Script:LocalPath,'assets/inc-monkey/logo/MonkeyLogo.png');
        }
        $img_attributes = @{
            src = $_iconPath;
            alt = 'monkey365';
        }
        $img_element = @{
            Name = 'img';
            Attributes = $img_attributes;
            Template = $TemplateObject;
        }
        $img = New-HtmlTag @img_element
        #create span element
        $span_attributes = @{
            class = 'align-middle me-3';
        }
        $span_element = @{
            Name = 'span';
            Text = "Monkey365";
            InnerText = $true;
            Attributes = $span_attributes;
            Template = $TemplateObject;
        }
        #Create a element and combine with H4
        $span = New-HtmlTag @span_element
        #Add span and img to a tag
        [void]$a_href.AppendChild($img);
        [void]$a_href.AppendChild($span);
        #Add to div header
        [void]$DivHeaderTag.AppendChild($a_href);
        #add header to sidebar
        [void]$sidebar.AppendChild($DivHeaderTag);
        #Create ul side-nav
        $sideNav = $TemplateObject.CreateNode(
            [System.Xml.XmlNodeType]::Element,
            $TemplateObject.Prefix,
            "ul",
            $TemplateObject.NamespaceURI
        );
        #Set attributes
        [void]$sideNav.SetAttribute("class","side-nav")
        #Add Title
        $LiElement = @{
            Name = 'li';
            ClassName = 'side-nav-title';
            Text = "Findings";
            InnerText = $true;
            Template = $TemplateObject;
        }
        #Create div element
        $LiTag = New-HtmlTag @LiElement
        #Add to sideNav
        [void]$sideNav.AppendChild($LiTag);
        ######Create ul and li elements ########
        $LiAttributes = @{
            class = 'side-nav-item';
        }
        $LiElement = @{
            Name = 'li';
            Attributes = $LiAttributes;
            Template = $TemplateObject;
        }
        #Create LI element
        $SideNavItem = New-HtmlTag @LiElement
        #Create basic li tag
        $basicLi = New-HtmlTag -Name "li" -Template $TemplateObject
        #Create span tag
        $basicSpan = @{
            Name = 'span';
            Template = $TemplateObject;
        }
        $spanTag = New-HtmlTag @basicSpan
        #Create i tag
        $basicITag = @{
            Name = 'i';
            Template = $TemplateObject;
        }
        $iTag = New-HtmlTag @basicITag
        #Create a tag
        $aAttributes = @{
            class = 'side-nav-link';
            "data-bs-toggle" = 'collapse';
            "aria-expanded" = 'true';
        }
        $basicATag = @{
            Name = 'a';
            Attributes = $aAttributes;
            Template = $TemplateObject;
        }
        $SideNavLink = New-HtmlTag @basicATag
        #Add i and span tags to a link
        [void]$SideNavLink.AppendChild($iTag);
        [void]$SideNavLink.AppendChild($spanTag);
        #Create div collapse
        $DivElement = @{
            Name = 'div';
            ClassName = 'collapse';
            Template = $TemplateObject;
        }
        #Create div element
        $DivCollapseTag = New-HtmlTag @DivElement
        #Create second level UL tag
        $ULElement = @{
            Name = 'ul';
            ClassName = 'side-nav-second-level';
            Template = $TemplateObject;
        }
        #Create ul element
        $SideNavSecondLevel = New-HtmlTag @ULElement
        #Create A tag and span for second level
        $aSecondLevel = New-HtmlTag -Name a -Template $TemplateObject
        $spanSecondLevel = New-HtmlTag -Name span -ClassName asset -Template $TemplateObject
        #Add span to a tag
        [void]$aSecondLevel.AppendChild($spanSecondLevel);
        ##Add to basic li
        [void]$basicLi.AppendChild($aSecondLevel);
        #Create basic side-nav-item
        $basicSideNavItem = $SideNavItem.Clone();
        $basicAHrefObject = New-HtmlTag -Name a -Template $TemplateObject
        $basicSpanObject = New-HtmlTag -Name span -Template $TemplateObject
        $basicIObject = $iTag.Clone()
        #Add i and span tags to a link
        [void]$basicAHrefObject.AppendChild($basicIObject);
        [void]$basicAHrefObject.AppendChild($basicSpanObject);
        #Add to basic SideNav object
        [void]$basicSideNavItem.AppendChild($basicAHrefObject);

    }
    Process{
        #Get sidebar items
        $sidebarItems = $InputObject | Group-Object -Property serviceName -ErrorAction Ignore
        Foreach($sidebarItem in $sidebarItems){
            If (-NOT [String]::IsNullOrEmpty($sidebarItem.Name)){
                Write-Verbose ($Script:messages.GenericAppendMessage -f $sidebarItem.Name,"HTML sidebar")
                #Get SideBar item
                $_SideNavItem = $SideNavItem.Clone()
                $icon = $sidebarItem.Name | Get-FabricIcon
                $_SideNavLink = $SideNavLink.Clone()
                #Get I
                $I_SideNavLink = $_SideNavLink.SelectSingleNode('//i')
                [void]$I_SideNavLink.SetAttribute('class',("{0} nav-icon" -f $icon))
                #Set a href
                $random_item = ("menu_{0}" -f ([System.Guid]::NewGuid().Guid.Replace('-','')))
                [void]$_SideNavLink.SetAttribute('href',('#{0}' -f $random_item))
                [void]$_SideNavLink.SetAttribute('aria-controls',$random_item.Split("_")[1])
                #Set span
                $span_SideNavLink = $_SideNavLink.SelectSingleNode('//span')
                [void]$span_SideNavLink.AppendChild($TemplateObject.CreateTextNode($sidebarItem.Name.ToString()))
                #Add to sidenav Item
                [void]$_SideNavItem.AppendChild($_SideNavLink);
                #Working with second level
                $secondLevelItems = $sidebarItem.Group | Select-Object -ExpandProperty ServiceType -Unique
                $_SideNavSecondLevel = $SideNavSecondLevel.Clone()
                $_DivCollapseTag = $DivCollapseTag.Clone()
                [void]$_DivCollapseTag.SetAttribute('id',$random_item)
                Foreach($secondLevelItem in @($secondLevelItems)){
                    #Get Li object
                    $_basicLi = $basicLi.Clone()
                    #Get Span
                    $_span = $_basicLi.SelectSingleNode('//span[contains(@class,"asset")]')
                    #Get image
                    $_svg = $secondLevelItem | Get-SvgIcon -Raw
                    If($_svg){
                        [void]$_span.AppendChild($TemplateObject.ImportNode($_svg.get_DocumentElement(), $True))
                    }
                    #Get A link
                    $_a = $_basicLi.SelectSingleNode('//a')
                    [void]$_a.SetAttribute('href',("javascript:show('{0}')" -f $secondLevelItem.ToLower().Replace(' ','-')))
                    #Add text
                    [void]$_a.AppendChild($TemplateObject.CreateTextNode($secondLevelItem))
                    #Add to sidenavSecondLevel
                    [void]$_SideNavSecondLevel.AppendChild($_basicLi);
                }
                #Add second level to div
                [void]$_DivCollapseTag.AppendChild($_SideNavSecondLevel);
                #Add to sidenavItem
                [void]$_SideNavItem.AppendChild($_DivCollapseTag);
            }
            #Add to sidenav
            [void]$sideNav.AppendChild($_SideNavItem);
        }
        #Add docs, execution info, etc..
        $_sideNavTitle = $LiTag.Clone();
        $_sideNavTitle.InnerText = "Scan Information"
        #Add to sideNav
        [void]$sideNav.AppendChild($_sideNavTitle);
        #Clone object
        $_SideNavItem = $basicSideNavItem.Clone();
        #Get Span
        $_span = $_SideNavItem.SelectSingleNode('//span');
        #Add text
        [void]$_span.AppendChild($TemplateObject.CreateTextNode("Execution Details"));
        #Get i
        $_i = $_SideNavItem.SelectSingleNode('//i');
        #Add class
        [void]$_i.SetAttribute('class',"bi bi-terminal nav-icon");
        #Get a
        $_a = $_SideNavItem.SelectSingleNode('//a');
        [void]$_a.SetAttribute('class','side-nav-link');
        [void]$_a.SetAttribute('href',"javascript:show('execution-info')")
        #Add to sidenav
        [void]$sideNav.AppendChild($_SideNavItem);
        #Add resources
        $_sideNavTitle = $LiTag.Clone();
        $_sideNavTitle.InnerText = "Resources"
        #Add to sideNav
        [void]$sideNav.AppendChild($_sideNavTitle);
        #Add documentation
        #Clone object
        $_SideNavItem = $basicSideNavItem.Clone();
        #Get Span
        $_span = $_SideNavItem.SelectSingleNode('//span');
        #Add text
        [void]$_span.AppendChild($TemplateObject.CreateTextNode("Documentation"));
        #Get i
        $_i = $_SideNavItem.SelectSingleNode('//i');
        #Add class
        [void]$_i.SetAttribute('class',"bi bi-file-earmark-text nav-icon");
        #Get a
        $_a = $_SideNavItem.SelectSingleNode('//a');
        [void]$_a.SetAttribute('class','side-nav-link');
        [void]$_a.SetAttribute('href',"https://silverhack.github.io/monkey365/");
        [void]$_a.SetAttribute('target','_blank');
        #Add to sidenav
        [void]$sideNav.AppendChild($_SideNavItem);
        #Add support
        $_SideNavItem = $basicSideNavItem.Clone();
        #Get Span
        $_span = $_SideNavItem.SelectSingleNode('//span');
        #Add text
        [void]$_span.AppendChild($TemplateObject.CreateTextNode("Support"));
        #Get i
        $_i = $_SideNavItem.SelectSingleNode('//i');
        #Add class
        [void]$_i.SetAttribute('class',"bi bi-info-circle nav-icon");
        #Get a
        $_a = $_SideNavItem.SelectSingleNode('//a');
        [void]$_a.SetAttribute('class','side-nav-link');
        [void]$_a.SetAttribute('href',"https://github.com/silverhack/monkey365/issues");
        [void]$_a.SetAttribute('target','_blank');
        #Add to sidenav
        [void]$sideNav.AppendChild($_SideNavItem);
        #Add about
        $_SideNavItem = $basicSideNavItem.Clone();
        #Get Span
        $_span = $_SideNavItem.SelectSingleNode('//span');
        #Add text
        [void]$_span.AppendChild($TemplateObject.CreateTextNode("About Monkey365"));
        #Get i
        $_i = $_SideNavItem.SelectSingleNode('//i');
        #Add class
        [void]$_i.SetAttribute('class',"bi bi-shield-shaded nav-icon");
        #Get a
        $_a = $_SideNavItem.SelectSingleNode('//a');
        [void]$_a.SetAttribute('class','side-nav-link');
        [void]$_a.SetAttribute('data-bs-target',"#aboutMonkeyModal");
        [void]$_a.SetAttribute('data-bs-toggle','modal');
        #Add to sidenav
        [void]$sideNav.AppendChild($_SideNavItem);
        #Add to sidebar
        [void]$sidebar.AppendChild($sideNav);
    }
    End{
        return $sidebar
    }
}
