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

Function Update-SideBar{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-SideBar
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Low")]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Sidebar Object')]
        [Object]$sidebar,

        [Parameter(Mandatory = $false, HelpMessage = 'Dashboard Object')]
        [Object]$dashboards
    )
    Begin{
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        $node = $sidebar.SelectSingleNode('//div[contains(@class,"header")]')
        ######Create ul and li elements ########
        $ul_attributes = @{
            class = 'nav-item';
        }
        $ul_element = @{
            tagname = 'ul';
            attributes = $ul_attributes;
            innerText = $null;
            own_template = $sidebar;
        }
        #Create a href
        $a_menu_attributes = @{
            href = $null;
            class = 'nav-link collapsed';
            'data-bs-toggle' = 'collapse';
            'aria-expanded' = $false;
        }
        $a_menu_element = @{
            tagname = 'a';
            attributes = $a_menu_attributes;
            appendObject = $null;
            own_template = $sidebar;
        }
        #Create UL element
        $unit_ul = New-HtmlTag @ul_element
        #Create LI element
        $unit_li = New-HtmlTag -tagname "li" -own_template $sidebar
    }
    Process{
        if ($PSCmdlet.ShouldProcess("ShouldProcess?")){
            if($null -ne $dashboards){
                #Create P element
                $p = $sidebar.CreateElement("p")
                [void]$p.SetAttribute('class','text-gray fw-bold text-uppercase px-3 small pb-1 mb-0')
                $p.InnerText = "Main"
                #Create UL element
                $ul = $unit_ul.clone()
                #Create LI element
                $li = $unit_li.clone()
                #Create I element
                $i = $sidebar.CreateElement("i")
                [void]$i.SetAttribute('class','bi bi-speedometer2 nav-icon')
                #Create a href and append i element
                $random_item = ("menu_{0}" -f ([System.Guid]::NewGuid().Guid.Replace('-','')))
                $a_menu_attributes.href = ('#{0}' -f $random_item)
                $a_menu_element.appendObject = $i
                $a = New-HtmlTag @a_menu_element
                #Add text
                [void]$a.AppendChild($sidebar.CreateTextNode("Dashboards"))
                #Append a to li element
                [void]$li.AppendChild($a)
                #Create UL
                $sub_ul = $sidebar.CreateElement("ul")
                [void]$sub_ul.SetAttribute('class','nav-submenu collapse')
                [void]$sub_ul.SetAttribute('id',$random_item)
                foreach($section in $dashboards){
                    #Create li element
                    $sub_li = $sidebar.CreateElement("li")
                    #Create span element
                    $span = $sidebar.CreateElement("span")
                    [void]$span.SetAttribute('class','asset')
                    #Create img element
                    $img = $sidebar.CreateElement("img")
                    [void]$img.SetAttribute('class','manImg')
                    [void]$img.SetAttribute('src',(Get-HtmlIcon -icon_name "a"))
                    #Append to span element
                    [void]$span.AppendChild($img)
                    #Create a element
                    $a = $sidebar.CreateElement("a")
                    [void]$a.SetAttribute('href',("javascript:show('{0}')" -f $section.id))
                    #Combine elements
                    [void]$a.AppendChild($span)
                    #Add text
                    [void]$a.AppendChild($sidebar.CreateTextNode($section.name))
                    #Append to li element
                    [void]$sub_li.AppendChild($a)
                    #Add to UL element
                    [void]$sub_ul.AppendChild($sub_li)
                }
                #Add to li element
                [void]$li.AppendChild($sub_ul)
                #Close i tags
                $i = $li.SelectNodes("//i")
                $i | ForEach-Object {$_.InnerText = [string]::Empty}
                #Add to first UL element
                [void]$ul.AppendChild($li)
                #Add to sidebar
                [void]$node.ParentNode.InsertAfter($ul, $node)
                [void]$node.ParentNode.InsertAfter($p, $node)
            }
        }
    }
    End{
        return $sidebar
    }
}


