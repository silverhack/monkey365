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

Function Build-HtmlChart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Build-HtmlChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$dataChart
    )
    Begin{
        $new_chartCard = $null
        $jsonChart= $null
        #Chart Template
        [xml]$chartTemplate = '<div><canvas><script></script></canvas></div>'
        if($null -ne $dataChart.PSObject.Properties.Item('groupby')){
            $jsonChart = New-GroupByChart -dataChart $dataChart
        }
        elseif($null -ne $dataChart.PSObject.Properties.Item('path') -and $dataChart.path -is [string]){
            $jsonChart = New-Chart -dataChart $dataChart
        }
        if($null -ne $dataChart.PSObject.Properties.Item('chartSize') -and $dataChart.chartSize -eq "small"){
            $chartClass = "align-self-center chart chart-xs"
            $colClass = 'justify-content-center col-12 col-lg-6 col-xl-4 grid-margin'

        }
        elseif($null -ne $dataChart.PSObject.Properties.Item('chartSize') -and $dataChart.chartSize -eq "large"){
            $chartClass = "align-self-center chart chart-lg"
            $colClass = 'justify-content-center col-12 col-lg-12 col-xl-12 grid-margin'
        }
        else{
            $chartClass = "align-self-center chart chart-xs"
            $colClass = 'justify-content-center col-12 col-lg-6 col-xl-4 grid-margin'
        }
    }
    Process{
        if($null -ne $jsonChart){
            $chart_id = ("monkey_chart_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
            #Get main Div
            $div = $chartTemplate.SelectSingleNode('//div')
            #Set main class
            [void]$div.SetAttribute('class',$chartClass)
            #Get canvas
            $canvas = $chartTemplate.SelectSingleNode('//canvas')
            #Set canvas id
            [void]$canvas.SetAttribute('id',$chart_id)
            #set canvas classw
            [void]$canvas.SetAttribute('class','chartjs-render-monitor')
            #Get script
            $script = $chartTemplate.SelectSingleNode('//script')
            #set Script data
            $script_data = ('new Chart(document.getElementById("{0}"),{1})' -f $chart_id,$jsonChart.ToString())
            $script.InnerText = $script_data
            #Add chart to box
            if($null -ne $dataChart.PSObject.Properties.Item('box') -and $dataChart.box){
                #Get Title
                if($null -ne ($dataChart.box.psobject.properties.Item('title'))){
                    $title = $dataChart.box.title;
                }
                else{
                    $title = "";
                }
                #Get subtitle
                if($null -ne ($dataChart.box.psobject.properties.Item('subtitle'))){
                    $subtitle = $dataChart.box.subtitle;
                }
                else{
                    $subtitle = "";
                }
                #Get img
                if($null -ne ($dataChart.box.psobject.properties.Item('img'))){
                    $img = $dataChart.box.img;
                }
                else{
                    $img = "";
                }
                #Get i class
                if($null -ne ($dataChart.box.psobject.properties.Item('i_class'))){
                    $i_class = $dataChart.box.i_class;
                }
                else{
                    $i_class = "";
                }
                $boxArgs = @{
                    defaultCard = $True;
                    card_class = 'monkey-card';
                    title_header = $title;
                    subtitle = $subtitle;
                    img = $img;
                    i_class = $i_class;
                    body = $chartTemplate;
                }
                #Get new html card
                $new_chartCard = Get-HtmlCard @boxArgs
                #Add d-flex class to body
                $div = $new_chartCard.SelectSingleNode('//div[contains(@class,"card-body")]')
                if($div){
                    [void]$div.SetAttribute('class','card-body d-flex')
                }
            }
            else{
                Write-Verbose ($script:messages.UnableToInsertChartMissingBox)
            }
            if($null -ne $new_chartCard){
                #main col
                [xml]$mainCol = '<div></div>'
                #import card
                $new_chartCard = $mainCol.ImportNode($new_chartCard.get_DocumentElement(), $True)
                #add chart to main col
                [void]$mainCol.DocumentElement.SetAttribute('class',$colClass)
                #add card to div
                [void]$mainCol.DocumentElement.AppendChild($new_chartCard)
            }
            else{
                Write-Warning ($script:messages.UnableToGetChart)
                $mainCol = $null
            }
        }
        else{
            $mainCol = $null
        }
    }
    End{
        if($mainCol -is [System.Xml.XmlDocument]){
            return $mainCol
        }
        else{
            return $null
        }
    }
}

