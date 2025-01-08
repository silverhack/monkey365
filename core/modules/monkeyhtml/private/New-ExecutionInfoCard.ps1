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

function New-ExecutionInfoCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-ExecutionInfoCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    Begin{
        $main_div = [xml] '<div class="text-center"></div>'
        #Create container element
        $scan_container = $main_div.CreateElement("div")
        [void]$scan_container.SetAttribute('class','scan-details-container')
        #Create scan detail element
        $scan_detail = $main_div.CreateElement("div")
        [void]$scan_detail.SetAttribute('class','row scan-detail')
        #Attributes
        $label_attributes = @{
            class = 'col-md-3 scan-label';
        }
        $div_labels_elem = @{
            tagname = 'div';
            attributes = $label_attributes;
            innerText = $null;
            own_template = $main_div;
        }
        #Create div label element
        $div_label = New-HtmlTag @div_labels_elem
        #Create div info element
        $div_labels_elem.attributes.class = 'col-md-9 scan-info'
        $div_info = New-HtmlTag @div_labels_elem
    }
    Process{
        #Add elements
        foreach($elem in $Script:exec_info.GetEnumerator()){
            $div_details = $scan_detail.Clone()
            $label = $div_label.Clone()
            $info = $div_info.Clone()
            #Set label
            [void]$label.AppendChild($main_div.CreateTextNode($elem.Name))
            #Set info
            [void]$info.AppendChild($main_div.CreateTextNode($elem.Value))
            #Add to Div element
            [void]$div_details.AppendChild($label)
            [void]$div_details.AppendChild($info)
            #Add to container
            [void]$scan_container.AppendChild($div_details)
        }
        #Add container to main div
        $div = $main_div.SelectSingleNode("div")
        [void]$div.AppendChild($scan_container)
        #Get New card
        $params = @{
            defaultCard= $True;
            card_class = 'monkey-card h-100';
            card_category = "Execution info";
            title_header = 'Ruleset details';
            i_class = 'bi bi-list-check me-2';
            body = $main_div;
        }
        $card = Get-HtmlCard @params
    }
    End{
        if($null -ne $card){
            return $card
        }
        else{
            return $null
        }
    }
}

