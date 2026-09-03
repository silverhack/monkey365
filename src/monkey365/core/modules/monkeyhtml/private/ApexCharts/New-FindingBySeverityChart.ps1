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

Function New-FindingBySeverityChart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-FindingBySeverityChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Matched items')]
        [Object]$InputObject,

        [Parameter(Mandatory = $false, HelpMessage= "Donut chart")]
        [Switch]$Donut,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        #Declare arrays
        $labels = [System.Collections.Generic.List[System.String]]::new();
        $colors = [System.Collections.Generic.List[System.String]]::new();
        $data = [System.Collections.Generic.List[System.Int32]]::new();
        #Set null
        $chartOptions = $null;
    }
    Process{
        Try{
            #Get chart data
            $chartData = @($InputObject).Where({$_.level.ToLower() -ne 'good' -and $_.level.ToLower() -ne 'manual'}) | Group-Object -Property level | Sort-Object -Descending Name | Select-Object Name, Count
            #Populate data
            Foreach($service in @($chartData)){
                If($null -ne $service.Name){
                    #Add label
                    [void]$labels.Add($service.Name)
                    #Add data
                    [void]$data.Add($service.Count);
                    #Add color
                    $color = $service.Name | Get-ColorFromLevel
                    [void]$colors.Add(("var(--{0})" -f $color))
                }
            }
            If($data.Count -gt 0 -and $labels.Count -gt 0){
                #Get New id
                $newId = ("monkey_chart_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
                #Get chart options
                $p = @{
                    Data = $data;
                    Labels = $labels;
                    Id = $newId;
                    Colors = $colors;
                }
                If($PSBoundParameters.ContainsKey('Donut') -and $PSBoundParameters['Donut'].IsPresent){
                    $chartOptions = Get-DonutChartOption @p
                }
                Else{
                    $chartOptions = Get-PolarAreaChartOption @p
                }
                If($chartOptions){
                    #Create script properties
                    $scriptProperties = @{
                        Name = 'script';
                        Text = $chartOptions;
                        CreateTextNode = $true;
                        Template = $TemplateObject;
                    }
                    #Create element
                    $scriptContent = New-HtmlTag @scriptProperties
                    #Create div content
                    $divProperties = @{
                        Name = 'div';
                        ClassName = "chart chart-lg d-flex justify-content-center";
                        Id = $newId;
                        AppendObject = $scriptContent;
                        Template = $TemplateObject;
                    }
                    #Create element
                    $div = New-HtmlTag @divProperties
                    #Create new Card
                    $p = @{
                        CardTitle = "Findings By severity"
                        Icon = "bi bi-pie-chart me-2";
                        ClassName = "h-100";
                        AppendObject = $div;
                        Template = $TemplateObject;
                    }
                    $card = New-HtmlContainerCard @p
                    return $card
                }
                Else{
                    Write-Warning "Unable to create Severity chart"
                }
            }
            Else{
                Write-Warning "Unable to create Severity chart"
            }
        }
        Catch{
            Write-Warning "Unable to create Severity chart"
            Write-Error $_
        }
    }
}
