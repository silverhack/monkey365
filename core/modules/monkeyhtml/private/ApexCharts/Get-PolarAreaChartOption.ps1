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

Function Get-PolarAreaChartOption{
    <#
        .SYNOPSIS
        Get Apexchart's polar area chart options

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PolarAreaChartOption
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "Chart data")]
        [System.Array]$Data,

        [parameter(Mandatory= $false, HelpMessage= "Chart Id")]
        [String]$Id,

        [parameter(Mandatory= $false, HelpMessage= "Chart labels")]
        [System.Array]$Labels,

        [parameter(Mandatory= $false, HelpMessage= "Chart colors")]
        [System.Array]$Colors
    )
    Begin{
        #Chart options
        $jsonChart = [PsCustomObject]@{
            options = [PsCustomObject]@{
                series = $null;
		        colors = $null;
		        chart = [PsCustomObject]@{
			        width = 380;
			        type = 'polarArea';
		        };
		        labels = $null;
		        fill = [PsCustomObject]@{
			        colors = $null;
		        };
		        stroke = [PsCustomObject]@{
			        show = $true;
			        width = 2;
			        colors = 'var(--monkey-light)'
		        };
                yaxis = [PsCustomObject]@{
			        show = $false
		        };
                legend = [PsCustomObject]@{
			        position = 'bottom';
			        fontSize ='14px';
			        fontWeight = '500';
			        labels = [PsCustomObject]@{
				        colors = 'var(--monkey-gray-700)';
				        useSeriesColors = $false;
			        };
			        markers = [PsCustomObject]@{
				        width = 8;
				        height = 8;
			        }
		        };
                plotOptions = [PsCustomObject]@{
			        polarArea = [PsCustomObject]@{
				        rings = [PsCustomObject]@{
					        strokeWidth = 0;
				        };
				        spokes = [PsCustomObject]@{
					        strokeWidth = 0
				        };
			        }
		        }
            }
        }
        #Set memory stream and streamwriter
        $ms = [System.IO.MemoryStream]::new()
        $streamWriter = [System.IO.StreamWriter]::new($ms)
    }
    Process{
        #Add empty line
        $streamWriter.WriteLine([System.String]::Empty);
        #Check if labels
        If($PSBoundParameters.ContainsKey('Labels') -and $PSBoundParameters['Labels']){
            $_myLabels = @($PSBoundParameters['Labels']).ForEach({[String]::Format('"{0}"' -f $_)})
            $ChartLabels = [String]::Join(",",$_myLabels)
            $streamWriter.WriteLine(('var labels = [{0}];' -f $ChartLabels))
            #Add labels to dict
            $jsonChart.options.labels = '${labels}';
        }
        #Check if colors
        If($PSBoundParameters.ContainsKey('Colors') -and $PSBoundParameters['Colors']){
            $_myColors = @($PSBoundParameters['Colors']).ForEach({[String]::Format('"{0}"' -f $_)})
            $ChartColors = [String]::Join(",",$_myColors)
            $streamWriter.WriteLine(('var colors = [{0}];' -f $ChartColors))
            #Add colors to dict
            $jsonChart.options.colors = '${colors}';
            $jsonChart.options.fill.colors = '${colors}';
        }
        #Add data
        $jsonChart.options.series = $Data;
        $jsonOptions = $jsonChart.options | ConvertTo-Json -Depth 100
        $streamWriter.WriteLine("var options = {0}" -f $jsonOptions);
        #Check Id
        If($PSBoundParameters.ContainsKey('Id') -and $PSBoundParameters['Id']){
            $chartId = $PSBoundParameters['Id']
        }
        Else{
            $chartId = ("monkeyChart{0}" -f [System.Guid]::NewGuid().Guid.ToString().Replace('-',''))
        }
        #Add chart render
        $newChart = ('var chart = new ApexCharts(document.querySelector("#{0}"), options);' -f $chartId)
        $streamWriter.WriteLine($newChart);
        $streamWriter.WriteLine("chart.render();");
        #Add dict to streamwriter
        $streamWriter.Flush()
        [void]$ms.Seek(0,[System.IO.SeekOrigin]::Begin)
        $reader = [System.IO.StreamReader]::new($ms)
        $newChart = $reader.ReadToEnd();
        #Replace data
        If($PSBoundParameters.ContainsKey('Labels') -and $PSBoundParameters['Labels']){
            $newChart = $newChart -replace '"\${labels}"', "labels"
        }
        If($PSBoundParameters.ContainsKey('Colors') -and $PSBoundParameters['Colors']){
            $newChart = $newChart -replace '"\${colors}"', "colors"
        }
        return $newChart
    }
    End{
        $ms.Dispose()
        $streamWriter.Dispose()
        $reader.Dispose()
    }
}
