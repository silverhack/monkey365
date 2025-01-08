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

function New-DashboardIssuesChart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-DashboardIssuesChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    Begin{
        [xml]$main_div = '<div class="row justify-content-center"></div>'
        $riskElements = @(
            @{
                internal_risk_level = 'High';
                issue_level = 'High';
                issue_caption = 'Risk Issues';
                issue_text = "Issues";
                chart_color = 'circular-chart red'
            },
            @{
                internal_risk_level = 'medium';
                issue_level = 'Medium';
                issue_caption = 'Risk Issues';
                issue_text = "Issues";
                chart_color = 'circular-chart orange'
            },
            @{
                internal_risk_level = 'Info';
                issue_level = 'Low';
                issue_caption = 'Risk Issues';
                issue_text = "Issues";
                chart_color = 'circular-chart blue'
            },
            @{
                internal_risk_level = 'Good';
                issue_level = 'Good';
                issue_caption = 'Security Practices';
                issue_text = "Goods";
                chart_color = 'circular-chart green'
            }
        )
        $grouped_issues = $matched | Group-Object level
        #Number of issues
        $total_issues = @($matched).count
    }
    Process{
        #Iterate over all rates of risk
        foreach($risk in $riskElements){
            $risk_elems = $grouped_issues | Where-Object {$_.Name.ToLower() -eq $risk.internal_risk_level.ToString().ToLower()} | `
                                            Select-Object -ExpandProperty Count -ErrorAction SilentlyContinue
            if($null -ne $risk_elems){
                #$percentage = ($risk_elems/$total_issues).ToString('#0%')
                $percentage = ($risk_elems/$total_issues).tostring("P")
                #set chart args
                $chartArgs = @{total_issues = $total_issues;
                               percentage = $percentage;
                               issue_level = $risk.issue_level;
                               issue_caption = $risk.issue_caption;
                               issue_number = $risk_elems;
                               issue_text = $risk.issue_text;
                               chart_color = $risk.chart_color;
                }
                #Get chart
                $chart = New-CircularChart @chartArgs
                if($null -ne $chart){
                    $risk_chart = $main_div.ImportNode($chart.get_DocumentElement(), $True)
                    [void]$main_div.div.AppendChild($risk_chart)
                }

            }
        }
        #Get New panel
        $params = @{
            defaultCard= $True;
            card_class = 'monkey-card';
            card_category = "Dashboard";
            title_header = 'Azure Account Status';
            i_class = 'bi bi-bar-chart-line me-2';
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

