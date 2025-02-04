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

Function New-Chart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-Chart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$dataChart
    )
    Begin{
        $jsonChart = [ordered]@{
            type = $null
            data = @{
                labels = $null
                datasets = @()
            }
            options = @{}
        }
    }
    Process{
        $dataSets = @()
        $labels = New-Object System.Collections.Generic.List[string]
        #Create array
        #$outArray = New-Object System.Collections.Generic.List[System.Object]
        $selected_data = $Script:data | Select-Object -ExpandProperty $dataChart.path -Unique -ErrorAction Ignore
        if($null -ne $selected_data){
            $raw_data = $selected_data | Select-Object -ExpandProperty data
        }
        else{
            $raw_data = $null
        }
        if($null -ne $raw_data){
            foreach($property in $dataChart.data){
                $hashTable = [System.Collections.Specialized.OrderedDictionary]::new()
                $outHashTable = [System.Collections.Specialized.OrderedDictionary]::new()
                #check if property exists
                $property_exists = [bool]($raw_data | Get-Member -Name $property)
                if($property_exists){
                    Write-Verbose ($script:messages.GetChartProperty -f $property)
                    $chart_results = $raw_data | Group-Object -Property $property | `
                                                        Select-Object name, count
                    #format results
                    if(@($chart_results).Count -gt 1){
                        $chart_results = $chart_results.GetEnumerator() | Sort-Object -Descending Name
                    }
                    else{
                        $tmp = @{
                            Name = $chart_results.Name
                            Count = $chart_results.Count
                        }
                        $chart_results = New-Object -TypeName PSCustomObject -Property $tmp
                        $value = if($chart_results.Name -eq $True){$false}else{$True}
                        $fake = [pscustomObject]@{
                            Name = $value
                            Count = 0
                        }
                        $res = @()
                        $res+=$chart_results
                        $res+=$fake
                        $chart_results = $res | Sort-Object -Descending Name
                    }
                    $chart_results = Update-ChartData -chartData $chart_results
                    $values = New-Object System.Collections.Generic.List[string]
                    if($chart_results){
                        $chart_results | ForEach-Object {if($Labels -notcontains $_.Name){$labels.Add($_.Name)}}
                        $chart_results | ForEach-Object {$values.Add($_.count)}
                        $chart_results | ForEach-Object {$hashTable.Add($_.Name,$_.Count)}
                        $outHashTable.Add("label",$property)
                        $outHashTable.Add("data",$values)
                        #$outHashTable.Add("hashtable",$hashTable)
                        if($dataChart.dataSet){
                            if(@($dataChart.dataSet).Count -eq 1){
                                $ht2 = @{}
                                $dataChart.dataSet.psobject.properties | ForEach-Object { $ht2[$_.Name] = $_.Value }
                                $outHashTable = Merge-HashTable -default $outHashTable -uppend $ht2
                            }
                            elseif(@($dataChart.dataSet).Count -gt 1){
                                $a = @()
                                foreach($dataset in $dataChart.dataSet){
                                    $ht2 = @{}
                                    $dataset.psobject.properties | ForEach-Object { $ht2[$_.Name] = $_.Value }
                                    $a+=$ht2
                                }
                                $outHashTable = $a;
                            }
                        }
                        $dataSets+=$outHashTable
                    }
                }
                else{
                    Write-Verbose ($script:messages.UnableToGetProperty -f $property)
                }
            }
        }
        else{
            Write-Verbose ($script:messages.UnknownPath -f $dataChart.path)
        }
    }
    End{
        if($dataSets -and $labels){
            #Add labels to chart
            $jsonChart.data.labels = ($Labels | Select-Object -Unique)
            #Set chart type
            $jsonChart.type = $dataChart.chartType
            if($null -ne $dataChart.PSObject.Properties.Item('options') -and $dataChart.options){
                #set chart options
                $jsonChart.options = $dataChart.options
            }
            elseif($null -ne $dataChart.PSObject.Properties.Item('extra_options') -and $dataChart.extra_options){
                $jsonChart.options = '${extra_options}'
            }
            else{
                #remove options
                $jsonChart.Remove('options')
            }
            #add datasets
            $jsonChart.data.datasets = $dataSets
            #convertto JSON
            $jsonChart = $jsonChart | ConvertTo-Json -Depth 5
            #check if extra options
            if($null -ne $dataChart.PSObject.Properties.Item('extra_options') -and $dataChart.extra_options){
                $jsonChart = $jsonChart -replace '"\${extra_options}"', $dataChart.extra_options
            }
            #return object
            return $jsonChart
        }
        else{
            return $null
        }
    }
}


