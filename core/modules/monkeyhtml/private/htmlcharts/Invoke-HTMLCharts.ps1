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

Function Invoke-HTMLCharts{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-HTMLCharts
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$category
    )
    Begin{
        if($null -ne (Get-Variable -Name dcharts -ErrorAction Ignore)){
            $div = $null;
            #Row Template
            [xml]$rowTemplate = '<div class="container-fluid"><div class="row"></div></div>'
            #Get charts
            $all_charts = $dcharts | Select-Object -ExpandProperty $category -ErrorAction Ignore
            if($null -eq $all_charts){
                return;
            }
            #Set id
            $id = ("{0}_charts" -f $category.ToLower().Replace(' ','-'))
            [void]$rowTemplate.div.SetAttribute('id',$id)
            #[void]$rowTemplate.div.SetAttribute('style','display:none')
            $div = $rowTemplate.SelectSingleNode('//div[contains(@class,"row")]')
        }
        else{
            $all_charts = $null
            $div = $null
        }
    }
    Process{
        #iterate over charts
        if($null -ne $all_charts){
            foreach($dataChart in $all_charts.charts){
                Write-Verbose ($script:messages.NewChartMessage -f $dataChart.label)
                $new_chart = Build-HtmlChart -dataChart $dataChart
                if($new_chart){
                    #import chart
                    $new_chart = $rowTemplate.ImportNode($new_chart.get_DocumentElement(), $True)
                    [void]$div.AppendChild($new_chart)
                }
            }
        }
    }
    End{
        try{
            if($null -ne $div -and $div -is [System.Xml.XmlElement] -and $null -ne $div.LastChild -and $div.LastChild.HasChildNodes){
                return $rowTemplate
            }
            else{
                Write-Debug ($script:messages.EmptyChartsForResource -f $category)
                return $null
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}


