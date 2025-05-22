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

Function New-HtmlCardFilter{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlCardFilter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(Mandatory = $false, ValueFromPipeline = $True, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        #Create button and input array
        $buttons = @(
            @{
                Name = "input"
                Attributes = [ordered]@{
                    class = "form-control finding-filter margin-right-sm";
                    placeholder = "Filter findings";
                    "aria-label" = "Filter findings";
                    type = "text";
                    autofocus = "true";
                    id = ("findingfilter_{0}" -f (Get-Random -Minimum 20 -Maximum 1000));
                };
            },
            @{
                Name = "button"
                Attributes = [ordered]@{
                    class = "btn btn-light btn-sm rounded-3 btn-filter";
                    type = "submit";
                    'data-filter-name' = "all";
                };
                Text = 'Show All';
            },
            @{
                Name = "button"
                Attributes = [ordered]@{
                    class = "btn btn-success btn-sm rounded-3 btn-filter"
                    type = "submit";
                    'data-filter-name' = "good"
                };
                Text = 'Good';
            },
            @{
                Name = "button"
                Attributes = [ordered]@{
                    class = "btn btn-info btn-sm rounded-3 btn-filter"
                    type = "submit";
                    'data-filter-name' = "info"
                };
                Text = 'Info';
            },
            @{
                Name = "button"
                Attributes = [ordered]@{
                    class = "btn btn-primary btn-sm rounded-3 btn-filter"
                    type = "submit";
                    'data-filter-name' = "low"
                };
                Text = 'Low';
            },
            @{
                Name = "button"
                Attributes = [ordered]@{
                    class = "btn btn-warning btn-sm rounded-3 btn-filter"
                    type = "submit";
                    'data-filter-name' = "warning"
                };
                Text = 'Medium';
            },
            @{
                Name = "button"
                Attributes = [ordered]@{
                    class = "btn btn-danger btn-sm rounded-3 btn-filter"
                    type = "submit";
                    'data-filter-name' = "danger"
                };
                Text = 'High';
            }
        )
        #Set template
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        #Create filter form
        $div = $TemplateObject.CreateNode(
            [System.Xml.XmlNodeType]::Element,
            $TemplateObject.Prefix,
            "div",
            $TemplateObject.NamespaceURI
        );
        #Set attributes
        [void]$div.SetAttribute("class","input-group");
        [void]$div.SetAttribute("id",("search_{0}" -f (Get-Random -Minimum 20 -Maximum 1000)));
    }
    Process{
        Foreach($element in $buttons){
            #Set h4 element
            $NewElement = @{
                Name = $element.Name;
                Attributes = $element.Attributes;
                Text = $element.Text;
                InnerText = $true;
                Template = $TemplateObject;
            }
            #Create element
            $newObject = New-HtmlTag @NewElement
            If($null -ne $newObject){
                #Append to div
                [void]$div.AppendChild($newObject);
            }
        }
        #return div
        return $div
    }
}
