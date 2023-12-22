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

Function New-DashboardTable{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-DashboardTable
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    Begin{
        $table = [xml] '<table id="dashboard_table" class="monkey-table table-hover responsive nowrap" width="100%"><thead><tr><th>Services</th><th>Resources</th><th>Rules</th><th>Findings</th></tr></thead><tbody></tbody><tfoot><tr><td colspan="5" class="text-center">data</td></tr></tfoot></table>'
        #Flagged elements
        $flagged = $matched |Group-Object serviceType
        $flagged = $flagged | Select-Object Name, @{Name='resources';Expression={(($_.Group[0].resourcesCount()))}}, @{Name='flagged';Expression={@($_.Group | Where-Object {$_.level -ne "Good"}).Count}}
        foreach($flag in $flagged){
            $number_of_rules = @($rules | Where-Object {$_.serviceType -eq $flag.Name}).Count
            if( $null -eq $flag.flagged){
                $flag.flagged = 1;
            }
            $flag | Add-Member -Type NoteProperty -name rules -value $number_of_rules -Force
        }
        #Create p element object
        $p_attributes = @{
            class = 'monkey-table-resource';
        }
        $p_element = @{
            tagname = 'p';
            attributes = $p_attributes;
            innerText = $null;
            own_template = $table;
        }
        #create img element object
        $img_attributes = @{
            class = 'table-resource-img';
            src = $null;
            alt = 'card_img';
        }
        $img_element = @{
            tagname = 'img';
            attributes = $img_attributes;
            empty = $true;
            own_template = $table;
        }
        #create a element object
        $ahref_attributes = @{
            href = $null;
            class = "internal_link";
        }
        $a_element = @{
            tagname = 'a';
            attributes = $ahref_attributes;
            own_template = $table;
        }
        #create span element object
        $span_attributes = @{
            class = 'badge rounded-pill bg-primary larger-badge';
        }
        $span_element = @{
            tagname = 'span';
            attributes = $span_attributes;
            innerText = $null;
            own_template = $table;
        }
    }
    Process{
        $tbody = $table.SelectSingleNode("table/tbody")
        $tr = $table.CreateElement("tr")
        $td = $table.CreateElement("td")
        foreach($service in $flagged){
            #Create DIV
            $resource_div = $table.CreateElement("div")
            #create p element
            $p_element.innerText = $service.Name;
            $p_resource = New-HtmlTag @p_element
            #add resource to div
            if($null -ne $p_resource){
                [void]$resource_div.AppendChild($p_resource)
            }
            #Create img
            $img_attributes.src = (Get-HtmlIcon -icon_name $service.Name.ToLower());
            $img_resource = New-HtmlTag @img_element
            #Create main div
            $resource_main_div = $table.CreateElement("div")
            [void]$resource_main_div.SetAttribute('class', "resource")
            #Add data to main div
            if($null -ne $img_resource){
                [void]$resource_main_div.AppendChild($img_resource)
            }
            [void]$resource_main_div.AppendChild($resource_div)
            #Create a href
            $ahref_attributes.href = "javascript:show('{0}')" -f $service.Name.ToLower().Replace(' ','-')
            $ahref = New-HtmlTag @a_element
            if($null -ne $ahref){
                [void]$ahref.AppendChild($resource_main_div)
                #Add Service
                $service_td = $td.Clone()
                [void]$service_td.AppendChild($ahref)
            }
            #Create span element
            $span_element.innerText = $service.resources;
            $span_element.attributes.class = 'badge rounded-pill bg-primary larger-badge'
            $span = New-HtmlTag @span_element
            if($null -ne $span){
                #Create resources
                $resources_td = $td.Clone()
                [void]$resources_td.AppendChild($span)
            }
            #Create rules
            $span_element.innerText = $service.rules;
            $span_attributes.class = 'badge rounded-pill bg-info larger-badge'
            $span = New-HtmlTag @span_element
            if($null -ne $span){
                $rules_td = $td.Clone()
                [void]$rules_td.AppendChild($span)
            }
            #Create findings
            $span_element.innerText = $service.flagged;
            $span_attributes.class = 'badge rounded-pill bg-warning larger-badge'
            $span = New-HtmlTag @span_element
            if($null -ne $span){
                $findings_td = $td.Clone()
                [void]$findings_td.AppendChild($span)
            }
            #Add to tr
            if($service_td -and $resources_td -and $rules_td -and $findings_td){
                $my_tr = $tr.Clone()
                [void]$my_tr.AppendChild($service_td)
                [void]$my_tr.AppendChild($resources_td)
                [void]$my_tr.AppendChild($rules_td)
                [void]$my_tr.AppendChild($findings_td)
                #Add to tbody
                [void]$tbody.AppendChild($my_tr)
            }
        }
        #Adjust footer
        $number_of_columns = $table.table.thead.tr.th.Count
        [void]$table.table.tfoot.tr.td.SetAttribute("colspan", $number_of_columns)
        $table.table.tfoot.tr.td.InnerText = "Monkey365 Dashboard"
        #Get New card
        $params = @{
            defaultCard = $true;
            card_class = 'monkey-card';
            card_category = 'Dashboard Table';
            title_header = 'Resources';
            i_class = 'bi bi-table me-2';
            body = $table;
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
