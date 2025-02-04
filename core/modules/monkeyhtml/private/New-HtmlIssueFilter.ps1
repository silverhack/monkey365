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

Function New-HtmlIssueFilter{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlIssueFilter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param()
    Begin{
        #xml root
        $issue_filter_root = [xml]'<div class="input-group mb-3 g-3 d-flex justify-content-center mb-4" id="search"></div>'
        #Create Dict
        $button_dict = @{
            Good = 'Good';
            info = 'Info';
            low = 'Low';
            warning = 'Medium';
            danger = 'High';
            all = 'Show All';
        }
        #Create button array
        $buttons = @(
            [ordered]@{
                class = "btn btn-light btn-sm rounded-3 me-2 btn-filter"
                'data-filter-name' = "all"
            },
            [ordered]@{
                class = "btn btn-success btn-sm rounded-3 me-2 btn-filter"
                'data-filter-name' = "good"
            },
            [ordered]@{
                class = "btn btn-info btn-sm rounded-3 me-2 btn-filter"
                'data-filter-name' = "info"
            },
            [ordered]@{
                class = "btn btn-primary btn-sm rounded-3 me-2 btn-filter"
                'data-filter-name' = "low"
            },
            [ordered]@{
                class = "btn btn-warning btn-sm rounded-3 me-2 btn-filter"
                'data-filter-name' = "warning"
            },
            [ordered]@{
                class = "btn btn-danger btn-sm rounded-3 btn-filter"
                'data-filter-name' = "danger"
            }
            #Add id
            $issue_filter_root.div.id = ("search_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
        )
        #Set Input attributes
        $input_attrs = [ordered]@{
            class = "form-control finding-filter me-2"
            id = 'findingfilter'
            type = 'text'
            placeholder = 'Filter findings'
            autofocus = "true"
        }
    }
    Process{
        $input_object = @{
            tagname = 'input';
            attributes = $input_attrs;
            innerText = $null;
            own_template = $issue_filter_root;
        }
        $input_element = New-HtmlTag @input_object
        [void]$issue_filter_root.div.AppendChild($input_element)
        #Create buttons
        foreach($btn_element in $buttons){
            $btn_object = @{
                tagname = 'button';
                attributes = $btn_element;
                innerText = $button_dict.Item($btn_element.Item('data-filter-name'));
                own_template = $issue_filter_root;
            }
            $btn_element = New-HtmlTag @btn_object
            if($btn_element){
                [void]$issue_filter_root.div.AppendChild($btn_element)
            }
        }
    }
    End{
        return $issue_filter_root
    }
}


