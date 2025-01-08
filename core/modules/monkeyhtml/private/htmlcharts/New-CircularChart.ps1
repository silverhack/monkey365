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

function New-CircularChart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-CircularChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$total_issues,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$percentage,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$issue_level,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$issue_caption,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$issue_number,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$issue_text,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$chart_color = 'circular-chart green'
    )
    Begin{
        $circular_chart = [xml] '<div class="col-md-3 border-right"><svg viewBox="0 0 46 46"><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray="30, 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="20.35" class="percentage">30%</text></svg><div class="row text-center"><div class="col-6 border-right"><div class="h4 font-weight-bold mb-0 issue-level"></div><span class="small issue-caption"></span></div><div class="col-6"><div class="h4 font-weight-bold mb-0 issue-number"></div><span class="small issue-text"></span></div></div></div>'
    }
    Process{
        if($issue_level){
            $level = $circular_chart.SelectSingleNode('//div[contains(@class,"issue-level")]')
            $level.InnerText = $issue_level
        }
        if($issue_caption){
            $span = $circular_chart.SelectSingleNode('//span[contains(@class,"issue-caption")]')
            $span.InnerText = $issue_caption
        }
        if($issue_number){
            $number = $circular_chart.SelectSingleNode('//div[contains(@class,"issue-number")]')
            $number.InnerText = $issue_number
        }
        if($issue_text){
            $text = $circular_chart.SelectSingleNode('//span[contains(@class,"issue-text")]')
            $text.InnerText = $issue_text
        }
        #Working with svg color, text, etc..
        $svg = $circular_chart.SelectSingleNode("//svg")
        if($chart_color){
            [void]$svg.SetAttribute('class',$chart_color)
        }
        if($percentage){
            $svg.text.InnerText = $percentage
        }
        if($total_issues -and $issue_number){
            $svg.path[1].'stroke-dasharray' = ("{0},100" -f $issue_number)
        }
    }
    End{
        return $circular_chart
    }
}

