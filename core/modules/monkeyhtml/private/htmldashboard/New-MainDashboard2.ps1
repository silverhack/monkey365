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

Function New-MainDashboard2{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MainDashboard2
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
        #Get Issues by service box
        $issues_by_service = New-IssuesByServiceJsonChart
        if($issues_by_service -is [System.Xml.XmlNode]){
            $issues_by_service = $main_dashboard_template.ImportNode($issues_by_service.get_DocumentElement(), $True)
        }
        #Get Issues by severity box
        $issues_by_severity = New-IssuesBySeverityJsonChart
        if($issues_by_severity -is [System.Xml.XmlNode]){
            $issues_by_severity = $main_dashboard_template.ImportNode($issues_by_severity.get_DocumentElement(), $True)
        }
        #Get Dashboard Table
        $dashboard_table = New-DashboardTable
        if($dashboard_table -is [System.Xml.XmlNode]){
            $dashboard_table = $main_dashboard_template.ImportNode($dashboard_table.get_DocumentElement(), $True)
        }
    }
    Process{
        $div = $main_dashboard_template.SelectSingleNode("div")
        #Add col-md-4 with main charts
        $div_col = $main_dashboard_template.CreateElement("div")
        [void]$div_col.SetAttribute('class','col-md-8 grid-margin')
        [void]$div_col.AppendChild($issues_by_service);
        [void]$div.AppendChild($div_col);
        #Add col-md-4 with main charts
        $div_col = $main_dashboard_template.CreateElement("div")
        [void]$div_col.SetAttribute('class','col-md-4 grid-margin')
        [void]$div_col.AppendChild($issues_by_severity);
        [void]$div.AppendChild($div_col);
        #Add col 12 with dashboard table
        $div_col = $main_dashboard_template.CreateElement("div")
        [void]$div_col.SetAttribute('class','col-md-12 grid-margin')
        [void]$div_col.AppendChild($dashboard_table);
        [void]$div.AppendChild($div_col);
    }
    End{
        #return dashboard
        return $main_dashboard_template
    }
}


