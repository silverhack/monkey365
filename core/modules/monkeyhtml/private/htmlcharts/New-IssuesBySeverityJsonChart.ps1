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

Function New-IssuesBySeverityJsonChart {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-IssuesBySeverityJsonChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    Begin{
        $jsonchart = $null
        #Chart Template
        [xml]$chartTemplate = '<div class="chart chart-xs"><canvas><script></script></canvas></div>'
        #Set legend Id
        $legend_id = ("{0}-legend" -f (Get-Random -Minimum 20 -Maximum 1000))
        #Set col class
        #$colClass = 'col-md-4 grid-margin'
        $chartColors = @{
	        medium = '#FFCE56';
	        low = '#1f78b4';
	        Info = '#a6cee3';
	        high = '#e31a1c';
	        good = '#7fc97f';
	        critical = '#7570b3';
        }
        #Medium, Low, Info, High, Good, Critical
        $backgroundColor = New-Object System.Collections.Generic.List[string]
        $hoverBackgroundColor = New-Object System.Collections.Generic.List[string]
        $legendColor = New-Object System.Collections.Generic.List[string]
        $labels = New-Object System.Collections.Generic.List[string]
        #Get Data
        $chart_data = $matched | Group-Object -Property level | Sort-Object -Descending Name | Select-Object Name, Count
        if($null -ne $chart_data){
            #Get colors, set labels, etc..
            foreach($element in $chart_data){
                #Add label
                $labels.Add($element.Name)
                #Add backgroundColor
                $backgroundColor.Add($chartColors.Item($element.Name))
                #Add hoverBackgroundColor
                $hoverBackgroundColor.Add($chartColors.Item($element.Name))
                #Add legendColor
                $legendColor.Add($chartColors.Item($element.Name))
            }
            #Get Json data
            $param = @{
                chartData = $chart_data | Select-Object -ExpandProperty Count;
                chartType = "doughnut";
                backgroundColor = $backgroundColor;
                hoverBackgroundColor = $hoverBackgroundColor;
                legendColor = $legendColor;
                borderWidth= 5;
                labels = $labels;
                external_options= "IssuesBySeverityChartOptions";
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
            $script_data = ('var MyChart = new Chart(document.getElementById("{0}"),{1})' -f $chart_id,$jsonChart.ToString())
            $script.InnerText = $script_data
            #Set title
            $title = "Issues by severity";
            #Set description
            $subtitle = "";
            #Set icon
            $i_class = "bi bi-pie-chart me-2";
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
                    [void]$div.SetAttribute('class','card-body')
                }
            }
            #Add legend
            if($new_chartCard){
                #Add legend
                $card_title = $new_chartCard.SelectSingleNode('//div[contains(@class,"chart")]')
                #Create Div
                $div_legend = $new_chartCard.CreateElement("div")
                [void]$div_legend.SetAttribute('class','rounded-legend legend-vertical legend-bottom-left pt-4')
                #Set id
                [void]$div_legend.SetAttribute('id',$legend_id)
                #Force close tag <div>
                [void]$div_legend.AppendChild($new_chartCard.CreateWhitespace(""))
                #Append to card title
                [void]$card_title.AppendChild($div_legend)
                #Add script
                $new_src = $new_chartCard.CreateElement("script")
                $new_src.InnerText = ('$("#{0}").html(MyChart.generateLegend())' -f $legend_id)
                [void]$card_title.AppendChild($new_src)
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

#New-IssuesBySeverityJsonChart -raw_data $matched
