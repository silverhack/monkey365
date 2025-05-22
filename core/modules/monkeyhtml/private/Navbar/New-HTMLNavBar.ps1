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

function New-HTMLNavBar{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HTMLNavBar
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "Repository Url")]
        [String]$Url = "https://github.com/silverhack/monkey365",

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
        #Set nulls
        $b64Pic = $account = $null
        #Default image
        $defaultImg = 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4NCjwhLS0gR2VuZXJhdG9yOiBBZG9iZSBJbGx1c3RyYXRvciAxNy4xLjAsIFNWRyBFeHBvcnQgUGx1Zy1JbiAuIFNWRyBWZXJzaW9uOiA2LjAwIEJ1aWxkIDApICAtLT4NCjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+DQo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IiBoZWlnaHQ9IjUwcHgiIHdpZHRoPSI1MHB4IiB2aWV3Qm94PSIwIDAgNTAgNTAiIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDUwIDUwIiB4bWw6c3BhY2U9InByZXNlcnZlIj4NCjxwb2x5Z29uIG9wYWNpdHk9IjAuMSIgZmlsbD0iI0ZGRkZGRiIgcG9pbnRzPSIwLDAgNTAsMCA1MCw1MCAwLDUwICIvPg0KPHBvbHlnb24gb3BhY2l0eT0iMC4xIiBmaWxsPSIjMkIzMTM3IiBwb2ludHM9IjAsMCA1MCwwIDUwLDUwIDAsNTAgIi8+DQo8Zz4NCgk8cGF0aCBmaWxsPSIjNTlCNEQ5IiBkPSJNMzEuOSwxNS4xYzAsMy43LTMuMSw2LjktNi45LDYuOXMtNi45LTMuMS02LjktNi45czMuMS02LjksNi45LTYuOUMyOC43LDguMiwzMS45LDExLjQsMzEuOSwxNS4xIi8+DQoJPHBvbHlnb24gZmlsbD0iIzU5QjREOSIgcG9pbnRzPSIzMCwyNC40IDI1LDMxLjQgMjAsMjQuNCAxMi43LDI0LjQgMTIuNyw0MS44IDM3LjIsNDEuOCAzNy4yLDI0LjQgCSIvPg0KCTxwYXRoIG9wYWNpdHk9IjAuMiIgZmlsbD0iI0ZGRkZGRiIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAgICAiIGQ9Ik0xOC4xLDE1LjFjMCwzLjcsMyw2LjgsNi44LDYuOWwxLjYtMTMuNQ0KCQljLTAuNS0wLjEtMS0wLjEtMS41LTAuMUMyMS4xLDguMiwxOC4xLDExLjQsMTguMSwxNS4xIi8+DQoJPHBvbHlnb24gb3BhY2l0eT0iMC4yIiBmaWxsPSIjRkZGRkZGIiBlbmFibGUtYmFja2dyb3VuZD0ibmV3ICAgICIgcG9pbnRzPSIyMCwyNC40IDEyLjcsMjQuNCAxMi43LDQxLjggMjIuNCw0MS44IDIzLjksMjkuOSAJIi8+DQo8L2c+DQo8L3N2Zz4NCg=='
        #Create array objects
        $MainArray = [System.Collections.Generic.List[System.Object]]::new()
        $arrayObjects = [System.Collections.Generic.List[System.Object]]::new()
    }
    Process{
        Try{
            #Create NavBar
            $navbar = $TemplateObject.CreateNode(
                [System.Xml.XmlNodeType]::Element,
                $TemplateObject.Prefix,
                "nav",
                $TemplateObject.NamespaceURI
            );
            #Set class
            [void]$navbar.SetAttribute('class',"navbar navbar-expand")
            #Create container fluid div
            $DivElement = @{
                Name = 'div';
                attributes = @{
                    class = "container-fluid";
                };
                Template = $TemplateObject;
            }
            $ContainerFluidDiv = New-HtmlTag @DivElement
            #Create I hamburger object
            $IElement = @{
                Name = 'i';
                attributes = @{
                    class = "hamburger align-self-center";
                };
                Template = $TemplateObject;
            }
            $IObject = New-HtmlTag @IElement
            #Create span object and append I element
            $spanElement = @{
                Name = 'span';
                attributes = @{
                    class = "navbar-toggle d-flex";
                    id = "sidebarCollapse";
                };
                AppendObject = $IObject;
                Template = $TemplateObject;
            }
            $spanObject = New-HtmlTag @spanElement
            #Add to main array
            [void]$MainArray.Add($spanObject);
            #Create I object
            $IElement = @{
                Name = 'i';
                attributes = @{
                    class = "bi bi-search icon input-group-text";
                };
                Template = $TemplateObject;
            }
            $IObject = New-HtmlTag @IElement
            #Create input object
            $InputElement = @{
                Name = 'input';
                attributes = @{
                    type = "text";
                    class = "form-control search-filter";
                    placeholder = "Search";
                    "aria-label" = "Search";
                    "aria-describedby" = "monkey-addon1";
                };
                Template = $TemplateObject;
            }
            $_InputObject = New-HtmlTag @InputElement
            #Add to array
            [void]$arrayObjects.Add($IObject);
            [void]$arrayObjects.Add($_InputObject);
            #Create DIV
            $DivElement = @{
                Name = 'div';
                attributes = @{
                    class = "input-group input-group-navbar mb-3";
                };
                AppendObject = $arrayObjects;
                Template = $TemplateObject;
            }
            $DivObject = New-HtmlTag @DivElement
            #Add to array
            [void]$MainArray.Add($DivObject);
            #Create DIV for right element
            $DivElement = @{
                Name = 'div';
                attributes = @{
                    class = "navbar-collapse collapse navbar-adjust";
                    id = "navbar";
                };
                Template = $TemplateObject;
            }
            $NavBarCollapse = New-HtmlTag @DivElement
            #Create UL
            $ULElement = @{
                Name = 'ul';
                attributes = @{
                    class = "navbar-nav navbar-right d-flex align-items-center";
                };
                Template = $TemplateObject;
            }
            $NavBarRight = New-HtmlTag @ULElement
            $gitHubInfo = Get-HTMLNavBarGitHubInfo -Template $TemplateObject
            #Create Nav item
            $LiElement = @{
                Name = 'li';
                attributes = @{
                    class = "nav-item";
                };
                Template = $TemplateObject;
                AppendObject = $gitHubInfo;
            }
            $_li = New-HtmlTag @LiElement
            #Add to navbar right
            [void]$NavBarRight.AppendChild($_li);
            #Create theme changer icon
            $IElement = @{
                Name = 'i';
                attributes = @{
                    id = 'toggleTheme';
                    class = "bi bi-sun";
                };
                Template = $TemplateObject;
            }
            $_i = New-HtmlTag @IElement
            $DivElement = @{
                Name = 'div';
                attributes = @{
                    class = "nav-icon";
                };
                Template = $TemplateObject;
                AppendObject = $_i;
            }
            $_div = New-HtmlTag @DivElement
            #Create Nav item
            $LiElement = @{
                Name = 'li';
                attributes = @{
                    class = "nav-item";
                };
                Template = $TemplateObject;
                AppendObject = $_div;
            }
            $_li = New-HtmlTag @LiElement
            #Add to navbar right
            [void]$NavBarRight.AppendChild($_li);
            #Set Img object for user
            If($PSBoundParameters.ContainsKey('UserInfo') -and $null -ne $PSBoundParameters['UserInfo']){
                $b64Pic = $PSBoundParameters['UserInfo'] | Select-Object -ExpandProperty userpic -ErrorAction Ignore
                $account = $PSBoundParameters['UserInfo'] | Select-Object -ExpandProperty displayName -ErrorAction Ignore
            }
            ElseIf($null -ne (Get-Variable -Name ExecutionInfo -Scope Script -ErrorAction Ignore)){
                $b64Pic = $Script:ExecutionInfo | Select-Object -ExpandProperty userpic -ErrorAction Ignore
                $account = $Script:ExecutionInfo | Select-Object -ExpandProperty displayName -ErrorAction Ignore
            }
            Else{
                $b64Pic = $defaultImg;
                $account = "Unknown";
            }
            If($null -eq $b64Pic){$b64Pic = $defaultImg;}
            If($null -eq $account){$account = "Unknown";}
            #Create Img object
            $ImgElement = @{
                Name = 'img';
                attributes = @{
                    src = $b64Pic;
                    class = "rounded-circle";
                    alt = $account;
                };
                Template = $TemplateObject;
            }
            $ImgObject = New-HtmlTag @ImgElement
            #Set Username object
            $SpanElement = @{
                Name = 'span';
                attributes = @{
                    class = "monkey-username";
                    id = "username";
                };
                Text = $account;
                Template = $TemplateObject;
            }
            $SpanObject = New-HtmlTag @SpanElement
            #Create DIV and add img and span objects
            $DIVElement = @{
                Name = 'div';
                Attributes = @{
                    class = "avatar";
                };
                Template = $TemplateObject;
            }
            $DIVObject = New-HtmlTag @DIVElement
            #Add img and span
            [void]$DivObject.AppendChild($ImgObject);
            [void]$DivObject.AppendChild($SpanObject);
            #Append to nav-item
            $LiElement = @{
                Name = 'li';
                attributes = @{
                    class = "nav-item";
                };
                Template = $TemplateObject;
                AppendObject = $DivObject;
            }
            $_li = New-HtmlTag @LiElement
            #Add to navbar right
            [void]$NavBarRight.AppendChild($_li);
            #Add to navbarCollapse
            [void]$NavBarCollapse.AppendChild($NavBarRight);
            #Add to main array
            [void]$MainArray.Add($NavBarCollapse);
            #Populate objects
            Foreach($obj in $MainArray){
                [void]$ContainerFluidDiv.AppendChild($obj);
            }
            #Add to navbar
            [void]$navbar.AppendChild($ContainerFluidDiv);
            #Close i tags
            $all_i = $navbar.SelectNodes("//i")
            ForEach($i in $all_i){
                [void]$i.AppendChild($TemplateObject.CreateWhitespace(""))
            }
            #Close input tags
            $all_inputs = $navbar.SelectNodes("//input")
            ForEach($_input in $all_inputs){
                [void]$_input.AppendChild($TemplateObject.CreateWhitespace(""))
            }
            #Return object
            return $navbar
        }
        Catch{
            Write-Warning "Unable to create NavBar"
            Write-Error $_.Exception
        }
    }
    End{
        #Nothing to do here
    }
}