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

function New-HorizontalNavBar{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HorizontalNavBar
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Object with user info')]
        [Object]$user_info
    )
    Begin{
        $navbar = [xml] "<nav class='navbar navbar-expand navbar-light'><div class='container-fluid'><span class='sidebar-toggle d-flex' id='sidebarCollapse'><i class='hamburger align-self-center'/></span><div class='form-group search-box'><i class='bi bi-search form-control-search'/><input class='form-control search-filter mr-sm-2' type='text' placeholder='Search' aria-label='Search'/></div><div class='collapse navbar-collapse' id='navbarNav'><ul class='navbar-nav ms-auto'><li class='nav-item dropdown'><a class='nav-icon dropdown-toggle d-inline-block d-sm-none' href='#' data-bs-toggle='dropdown'/><a class='nav-link dropdown-toggle d-none d-sm-inline-block' href='#' data-bs-toggle='dropdown' aria-expanded='true'><img src='data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4NCjwhLS0gR2VuZXJhdG9yOiBBZG9iZSBJbGx1c3RyYXRvciAxNy4xLjAsIFNWRyBFeHBvcnQgUGx1Zy1JbiAuIFNWRyBWZXJzaW9uOiA2LjAwIEJ1aWxkIDApICAtLT4NCjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+DQo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IiBoZWlnaHQ9IjUwcHgiIHdpZHRoPSI1MHB4IiB2aWV3Qm94PSIwIDAgNTAgNTAiIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDUwIDUwIiB4bWw6c3BhY2U9InByZXNlcnZlIj4NCjxwb2x5Z29uIG9wYWNpdHk9IjAuMSIgZmlsbD0iI0ZGRkZGRiIgcG9pbnRzPSIwLDAgNTAsMCA1MCw1MCAwLDUwICIvPg0KPHBvbHlnb24gb3BhY2l0eT0iMC4xIiBmaWxsPSIjMkIzMTM3IiBwb2ludHM9IjAsMCA1MCwwIDUwLDUwIDAsNTAgIi8+DQo8Zz4NCgk8cGF0aCBmaWxsPSIjNTlCNEQ5IiBkPSJNMzEuOSwxNS4xYzAsMy43LTMuMSw2LjktNi45LDYuOXMtNi45LTMuMS02LjktNi45czMuMS02LjksNi45LTYuOUMyOC43LDguMiwzMS45LDExLjQsMzEuOSwxNS4xIi8+DQoJPHBvbHlnb24gZmlsbD0iIzU5QjREOSIgcG9pbnRzPSIzMCwyNC40IDI1LDMxLjQgMjAsMjQuNCAxMi43LDI0LjQgMTIuNyw0MS44IDM3LjIsNDEuOCAzNy4yLDI0LjQgCSIvPg0KCTxwYXRoIG9wYWNpdHk9IjAuMiIgZmlsbD0iI0ZGRkZGRiIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAgICAiIGQ9Ik0xOC4xLDE1LjFjMCwzLjcsMyw2LjgsNi44LDYuOWwxLjYtMTMuNQ0KCQljLTAuNS0wLjEtMS0wLjEtMS41LTAuMUMyMS4xLDguMiwxOC4xLDExLjQsMTguMSwxNS4xIi8+DQoJPHBvbHlnb24gb3BhY2l0eT0iMC4yIiBmaWxsPSIjRkZGRkZGIiBlbmFibGUtYmFja2dyb3VuZD0ibmV3ICAgICIgcG9pbnRzPSIyMCwyNC40IDEyLjcsMjQuNCAxMi43LDQxLjggMjIuNCw0MS44IDIzLjksMjkuOSAJIi8+DQo8L2c+DQo8L3N2Zz4NCg==' class='avatar img-fluid rounded-circle mr-1' alt='silverhack'/><span class='monkey-username' id='username'>silverhack</span></a><div class='dropdown-menu dropdown-menu-right'><a class='dropdown-item' href=''><i class='bi bi-terminal me-2'/>Execution Details</a><div class='dropdown-divider'/><a class='dropdown-item' data-bs-toggle='modal' data-bs-target='#aboutMonkeyModal'><i class='bi bi-shield-shaded me-2'/>About Monkey365</a><a class='dropdown-item' data-bs-toggle='modal' data-bs-target='#aboutAuthorModal'><i class='bi bi-at me-2'/>About Author</a><div class='dropdown-divider'/><div class='theme'><span class='inline-item'>Dark Theme</span><input type='checkbox' id='switch' name='theme'/><label class='switch' for='switch'/></div></div></li></ul></div></div></nav>"
    }
    Process{
        #Set Picture
        $img = $navbar.SelectSingleNode('//img[contains(@class,"avatar")]')
        if($img){
            try{
                [void]$img.SetAttribute('alt',$user_info.permissions.displayName)
            }
            catch{
                Write-Verbose $_
            }
            try{
                [void]$img.SetAttribute('src',$user_info.userpic)
            }
            catch{
                Write-Verbose $_
            }
        }
        #Set username
        $span = $navbar.SelectSingleNode('//span[contains(@id,"username")]')
        if($span){
            try{
                $span.InnerText = $user_info.permissions.displayName
            }
            catch{
                Write-Verbose $_
            }
        }
        #Set execution details
        $exec = $navbar.SelectSingleNode('//a[text() = "Execution Details"]')
        [void]$exec.SetAttribute('href',"javascript:show('execution-info')")
        #Close i tags
        $all_i = $navbar.SelectNodes("//i")
        foreach($i in $all_i){
            [void]$i.AppendChild($navbar.CreateWhitespace(""))
        }
        #Close separator div
        $divs = $navbar.SelectNodes('//div[contains(@class,"dropdown-divider")]')
        if($divs){
            foreach($div in $divs){
                [void]$div.AppendChild($navbar.CreateWhitespace(""))
            }
        }
        #Close input tags
        $all_inputs = $navbar.SelectNodes("//input")
        foreach($input in $all_inputs){
            [void]$input.AppendChild($navbar.CreateWhitespace(""))
        }
    }
    End{
        return $navbar
    }
}


