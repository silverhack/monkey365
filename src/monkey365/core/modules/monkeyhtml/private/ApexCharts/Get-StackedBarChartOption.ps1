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

Function Get-StackedBarChartOption{
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
            File Name	: Get-StackedBarChartOption
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $true, HelpMessage= "Chart data")]
        [System.Array]$Data,

        [parameter(Mandatory= $false, HelpMessage= "Chart Id")]
        [String]$Id,

        [parameter(Mandatory= $true, HelpMessage= "Chart labels")]
        [System.Array]$Labels,

        [Parameter(Mandatory = $false, HelpMessage= "Horizontal stacked")]
        [Switch]$Horizontal
    )
    Begin{
        #Chart options
        $jsonChart = [PsCustomObject]@{
            options = [PsCustomObject]@{
                series = $null;
		        chart = [PsCustomObject]@{
			        type = 'bar';
                    height = 350;
                    stacked = $true;
                    toolbar = [PsCustomObject]@{
						show = $false;
					};
					zoom = [PsCustomObject]@{
						enabled = $true;
					}
		        };
		        responsive = @(
                    [PsCustomObject]@{
			            breakpoint = 1000;
                        options = [PsCustomObject]@{
						    legend = [PsCustomObject]@{
                                position = 'bottom';
                                offsetX = -10;
                                offsetY = 0;
                            }
					    };
                    };
                );
		        plotOptions = [PsCustomObject]@{
			        bar = [PsCustomObject]@{
                        columnWidth = '${columnWidthPercent}';
                        horizontal = $false;
                        borderRadius = 10;
                        borderRadiusApplication = 'end';
                        borderRadiusWhenStacked = 'last';
                        dataLabels = [PsCustomObject]@{
			                total = [PsCustomObject]@{
                                enabled = $true;
                                style = [PsCustomObject]@{
                                    fontSize = '13px';
                                    fontWeight = 900;
                                }
                            }
		                };
			        }
		        }
                xaxis = [PsCustomObject]@{
			        type = 'string';
                    categories = $null;
                    labels = [PsCustomObject]@{
                        style = [PsCustomObject]@{
						    colors = 'var(--monkey-gray-700)';
                            fontSize = '13px';
                            fontWeight = 500;
					    };
		            };
		        };
                yaxis = [PsCustomObject]@{
                    labels = [PsCustomObject]@{
                        style = [PsCustomObject]@{
						    colors = 'var(--monkey-gray-700)';
                            fontSize = '13px';
                            fontWeight = 500;
					    };
		            };
		        };
                legend = [PsCustomObject]@{
			        position = 'right';
                    offsetY = 40;
			        fontSize ='13px';
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
                fill = [PsCustomObject]@{
			        opacity = 1;
		        };
            }
        }
        #Set memory stream and streamwriter
        $ms = [System.IO.MemoryStream]::new()
        $streamWriter = [System.IO.StreamWriter]::new($ms)
    }
    Process{
        #Add empty line
        $streamWriter.WriteLine([System.String]::Empty);
        #Add seriesLength
        $streamWriter.WriteLine(("var seriesLength = {0};" -f @($Labels).Count));
        #Set columnWidthPercent
        $streamWriter.WriteLine("var columnWidthPercent = 20 + (60 / (1 + 30*Math.exp(-seriesLength /3)));");
        #Check if labels
        If($PSBoundParameters.ContainsKey('Labels') -and $PSBoundParameters['Labels']){
            $_myLabels = @($PSBoundParameters['Labels']).ForEach({[String]::Format('"{0}"' -f $_)})
            $ChartLabels = [String]::Join(",",$_myLabels)
            $streamWriter.WriteLine(('var labels = [{0}];' -f $ChartLabels))
            #Add labels to dict
            $jsonChart.options.xaxis.categories = '${labels}';
        }
        #Check if horizontal
        If($PSBoundParameters.ContainsKey('Horizontal') -and $PSBoundParameters['Horizontal'].IsPresent){
            $jsonChart.options.plotOptions.bar.horizontal = $true;
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
        #Replace columnWidthPercent
        $newChart = $newChart -replace '"\${columnWidthPercent}"', 'columnWidthPercent + "%"'
        return $newChart
    }
    End{
        $ms.Dispose()
        $streamWriter.Dispose()
        $reader.Dispose()
    }
}
