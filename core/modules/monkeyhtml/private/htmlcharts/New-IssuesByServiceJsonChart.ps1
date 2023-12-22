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

Function New-IssuesByServiceJsonChart {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-IssuesByServiceJsonChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    Begin{
        #Chart Template
        [xml]$chartTemplate = '<div class="chart chart-lg"><canvas><script></script></canvas></div>'
        #Set col class
        #$colClass = 'col-md-8 grid-margin'
        #Set legend Id
        $legend_id = ("{0}-legend" -f (Get-Random -Minimum 20 -Maximum 1000))
        #Set vars
        $jsonchart = $null
        $labels = $null
        $non_flatten_array = @()
        $low_issues_array = @()
        $info_issues_array = @()
        $medium_issues_array = @()
        $good_security_practices_array = @()
        $high_issues_array = @()
        $critical_issues_array = @()
        #Medium, Low, Info, High, Good, Critical
        $backgroundColor = @("#FFCE56","#1f78b4","#a6cee3","#e31a1c","#7fc97f","#7570b3")
        $hoverBackgroundColor = @("#FFCE56","#1f78b4","#a6cee3","#e31a1c","#7fc97f","#7570b3")
        $legendColor = @("#FFCE56","#1f78b4","#a6cee3","#e31a1c","#7fc97f","#7570b3")
        #Group objects
        $grouped_elements = $matched | Group-Object serviceType | Sort-Object Name | Select-Object Name, Group
        #Get labels
        if($null -ne $grouped_elements){
            $labels = $grouped_elements | Select-Object -ExpandProperty Name
        }
        #Get extra labels
        $extra_labels = @("medium", "low", "info", "high", "good", "critical")
        #Populate arrays
        if($null -ne $grouped_elements){
            foreach($element in $grouped_elements){
                $issues = $element.Group | Group-Object -Property level | Select-Object Name, Count | Sort-Object -Descending Name
                #$total_issues = @()
                #Get medium issues
                $medium_issues = $issues | Where-Object {$_.Name -eq "medium"} | Select-Object -ExpandProperty Count
                if($null -eq $medium_issues){
                    $medium_issues = 0
                }
                #Add to array
                $medium_issues_array += $medium_issues
                #Get Low issues
                $low_issues = $issues | Where-Object {$_.Name -eq "low"} | Select-Object -ExpandProperty Count
                if($null -eq $low_issues){
                    $low_issues = 0
                }
                #Add to array
                $low_issues_array += $low_issues
                #Get Info issues
                $info_issues = $issues | Where-Object {$_.Name -eq "info"} | Select-Object -ExpandProperty Count
                if($null -eq $info_issues){
                    $info_issues = 0
                }
                #Add to array
                $info_issues_array += $info_issues
                #Get high issues
                $high_issues = $issues | Where-Object {$_.Name -eq "high"} | Select-Object -ExpandProperty Count
                if($null -eq $high_issues){
                    $high_issues = 0
                }
                #Add to array
                $high_issues_array += $high_issues
                #Get good security practices
                $good_issues = $issues | Where-Object {$_.Name -eq "good"} | Select-Object -ExpandProperty Count
                if($null -eq $good_issues){
                    $good_issues = 0
                }
                #Add to array
                $good_security_practices_array += $good_issues
                #Get critical issues
                $critical_issues = $issues | Where-Object {$_.Name -eq "critical"} | Select-Object -ExpandProperty Count
                if($null -eq $critical_issues){
                    $critical_issues = 0
                }
                #Add to array
                $critical_issues_array += $critical_issues
            }
            #Populate non flatten array
            $non_flatten_array = $medium_issues_array, $low_issues_array, $info_issues_array, $high_issues_array, $good_security_practices_array, $critical_issues_array
        }
        if($non_flatten_array.Length -gt 0){
            #Create json chart
            $param = @{
                chartData = $non_flatten_array;
                chartType = "bar";
                backgroundColor = $backgroundColor;
                hoverBackgroundColor = $hoverBackgroundColor;
                legendColor = $legendColor;
                borderWidth = 1;
                pointRadius = 0;
                barThickness = 38;
				maxBarThickness = 90;
                labels = $labels;
                nested_labels = $extra_labels;
                external_options= "IssuesByServiceChartOptions";
            }
            $jsonchart = New-JsonChart @param
        }
    }
    Process{
        if($null -ne $jsonchart){
            $chart_id = ("monkey_chart_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
            #Get canvas
            $canvas = $chartTemplate.SelectSingleNode('//canvas')
            #Set canvas id
            [void]$canvas.SetAttribute('id',$chart_id)
            #set canvas classw
            [void]$canvas.SetAttribute('class','chartjs-render-monitor')
            #Get script
            $script = $chartTemplate.SelectSingleNode('//script')
            #set Script data
            $script_data = ('var MyChart = new Chart(document.getElementById("{0}"),{1});$("#{2}").html(MyChart.generateLegend())' -f $chart_id,$jsonChart.ToString(), $legend_id)
            $script.InnerText = $script_data
            #Set title
            $title = "Issues by service";
            #Set description
            $subtitle = "";
            #Set icon
            $i_class = "bi bi-bar-chart-line me-2";
            #Get Box
            $boxArgs = @{
                defaultCard = $True;
                card_class = 'monkey-card h-100';
                title_header = $title;
                subtitle = $subtitle;
                i_class = $i_class;
                body = $chartTemplate;
            }
            #Get new html card
            $new_chartCard = Get-HtmlCard @boxArgs
            if($null -ne $new_chartCard){
                #Add d-flex class to body
                $div = $new_chartCard.SelectSingleNode('//div[contains(@class,"card-body")]')
                if($div){
                    [void]$div.SetAttribute('class','card-body d-flex')
                }
            }
            #Add legend
            if($new_chartCard){
                #Add legend
                $card_title = $new_chartCard.SelectSingleNode('//div[contains(@class,"card-title")]')
                #Create Div
                $div_legend = $new_chartCard.CreateElement("div")
                [void]$div_legend.SetAttribute('class','rounded-legend legend-horizontal legend-top-right float-end')
                #Set id
                [void]$div_legend.SetAttribute('id',$legend_id)
                #Force close tag <div>
                [void]$div_legend.AppendChild($new_chartCard.CreateWhitespace(""))
                #Append to card title
                [void]$card_title.AppendChild($div_legend)
            }
        }
    }
    End{
        if($new_chartCard -is [System.Xml.XmlDocument]){
            return $new_chartCard
        }
        else{
            return $null
        }
    }
}

#New-IssuesByServiceJsonChart -raw_data $matched
