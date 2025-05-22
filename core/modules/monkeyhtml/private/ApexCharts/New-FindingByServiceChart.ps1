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

Function New-FindingByServiceChart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-FindingByServiceChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Matched items')]
        [Object]$InputObject,

        [Parameter(Mandatory = $false, HelpMessage= "Horizontal stacked")]
        [Switch]$HorizontalStackedBar,

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
        $categories = [System.Collections.Generic.List[System.String]]::new();
        $series = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        $findingInfoObj = [PsCustomObject]@{
            name = 'Info';
            color = "var(--monkey-info)";
            data = [System.Collections.Generic.List[System.Int32]]::new();
        }
        $findingLowObj = [PsCustomObject]@{
            name = 'Low';
            color = "var(--monkey-low)";
            data = [System.Collections.Generic.List[System.Int32]]::new();
        }
        $findingMediumObj = [PsCustomObject]@{
            name = 'Medium';
            color = "var(--monkey-warning)";
            data = [System.Collections.Generic.List[System.Int32]]::new();
        }
        $findingHighObj = [PsCustomObject]@{
            name = 'High';
            color = "var(--monkey-danger)";
            data = [System.Collections.Generic.List[System.Int32]]::new();
        }
        $findingCriticalObj = [PsCustomObject]@{
            name = 'Critical';
            color = "var(--monkey-critical)";
            data = [System.Collections.Generic.List[System.Int32]]::new();
        }
    }
    Process{
        Try{
            #Group all EntraID findings
            $entraIdFindings = @($PSBoundParameters['InputObject']).Where({$_.Provider.ToLower() -eq 'entraid'})
            $info = $entraIdFindings.Where({$_.level -eq 'info'}).Count
            $low = $entraIdFindings.Where({$_.level -eq 'low'}).Count
            $medium = $entraIdFindings.Where({$_.level -eq 'medium'}).Count
            $high = $entraIdFindings.Where({$_.level -eq 'high'}).Count
            $critical = $entraIdFindings.Where({$_.level -eq 'critical'})
            If($info -ne 0 -or $low -ne 0 -or $medium -ne 0 -or $high -ne 0 -or $critical -ne 0){
                #Add to categories
                [void]$categories.Add('EntraId')
                #add findings count
                [void]$findingInfoObj.data.Add($entraIdFindings.Where({$_.level -eq 'info'}).Count)
                [void]$findingLowObj.data.Add($entraIdFindings.Where({$_.level -eq 'low'}).Count)
                [void]$findingMediumObj.data.Add($entraIdFindings.Where({$_.level -eq 'medium'}).Count)
                [void]$findingHighObj.data.Add($entraIdFindings.Where({$_.level -eq 'high'}).Count)
                [void]$findingCriticalObj.data.Add($entraIdFindings.Where({$_.level -eq 'critical'}).Count)
            }
            #Add rest of services
            $groupedFindings = @($PSBoundParameters['InputObject']).Where({$_.Provider.ToLower() -ne 'entraid'}) | Group-Object serviceType | Sort-Object Name | Select-Object Name, Group
            Foreach($service in $groupedFindings){
                $info = $service.Group.Where({$_.level -eq 'info'}).Count
                $low = $service.Group.Where({$_.level -eq 'low'}).Count
                $medium = $service.Group.Where({$_.level -eq 'medium'}).Count
                $high = $service.Group.Where({$_.level -eq 'high'}).Count
                $critical = $service.Group.Where({$_.level -eq 'critical'})
                If($info -ne 0 -or $low -ne 0 -or $medium -ne 0 -or $high -ne 0 -or $critical -ne 0){
                    #Add to categories
                    [void]$categories.Add($service.Name);
                    #add findings count
                    [void]$findingInfoObj.data.Add($service.Group.Where({$_.level -eq 'info'}).Count)
                    [void]$findingLowObj.data.Add($service.Group.Where({$_.level -eq 'low'}).Count)
                    [void]$findingMediumObj.data.Add($service.Group.Where({$_.level -eq 'medium'}).Count)
                    [void]$findingHighObj.data.Add($service.Group.Where({$_.level -eq 'high'}).Count)
                    [void]$findingCriticalObj.data.Add($service.Group.Where({$_.level -eq 'critical'}).Count)
                }
            }
            #Add data to series
            If(-NOT ($findingInfoObj.data | Sort-Object -Unique) -eq 0){
                [void]$series.Add($findingInfoObj);
            }
            If(-NOT ($findingLowObj.data | Sort-Object -Unique) -eq 0){
                [void]$series.Add($findingLowObj);
            }
            If(-NOT ($findingMediumObj.data | Sort-Object -Unique) -eq 0){
                [void]$series.Add($findingMediumObj);
            }
            If(-NOT ($findingHighObj.data | Sort-Object -Unique) -eq 0){
                [void]$series.Add($findingHighObj);
            }
            If(-NOT ($findingCriticalObj.data | Sort-Object -Unique) -eq 0){
                [void]$series.Add($findingCriticalObj);
            }
            #Get New id
            $newId = ("monkey_chart_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
            If($series.Count -gt 0 -and $categories.Count -gt 0){
                #Get chart options
                If($PSBoundParameters.ContainsKey('HorizontalStackedBar') -and $PSBoundParameters['HorizontalStackedBar'].IsPresent){
                    $p = @{
                        Data = $series;
                        Labels = $categories;
                        Id = $newId;
                        Horizontal = $true;
                    }
                }
                Else{
                    $p = @{
                        Data = $series;
                        Labels = $categories;
                        Id = $newId;
                    }
                }
                $chartOptions = Get-StackedBarChartOption @p
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
                        CardTitle = "Findings By Service"
                        Icon = "bi bi-bar-chart-line me-2";
                        ClassName = "h-100";
                        AppendObject = $div;
                        Template = $TemplateObject;
                    }
                    $card = New-HtmlContainerCard @p
                    return $card
                }
                Else{
                    Write-Warning "Unable to create findings chart"
                }
            }
            Else{
                Write-Warning "Unable to create findings chart"
            }
        }
        Catch{
            Write-Warning "Unable to create findings chart"
            Write-Error $_
        }
    }
}
