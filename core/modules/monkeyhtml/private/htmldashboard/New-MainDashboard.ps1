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

Function New-MainDashboard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MainDashboard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param()
    Begin{
        $main_dashboard_template = [xml] '<div class="row" id="monkey-main-dashboard"></div>'
        #Get HtmlCard
        $dashboard_issues = New-DashboardIssuesChart
        if($dashboard_issues -is [System.Xml.XmlNode]){
            $dashboard_issues = $main_dashboard_template.ImportNode($dashboard_issues.get_DocumentElement(), $True)
        }
        #Get Dashboard Table
        $dashboard_table = New-DashboardTable
        if($dashboard_table -is [System.Xml.XmlNode]){
            $dashboard_table = $main_dashboard_template.ImportNode($dashboard_table.get_DocumentElement(), $True)
        }
    }
    Process{
        $div = $main_dashboard_template.SelectSingleNode("div")
        #Add col 12 with main charts
        $div_col = $main_dashboard_template.CreateElement("div")
        [void]$div_col.SetAttribute('class','col-md-12')
        [void]$div_col.AppendChild($dashboard_issues);
        [void]$div.AppendChild($div_col);
        #Add col 12 with dashboard table
        $div_col = $main_dashboard_template.CreateElement("div")
        [void]$div_col.SetAttribute('class','col-md-12')
        [void]$div_col.AppendChild($dashboard_table);
        [void]$div.AppendChild($div_col);
    }
    End{
        #return dashboard
        return $main_dashboard_template
    }
}


