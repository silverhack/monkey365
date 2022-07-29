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

Function New-GroupByChart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-GroupByChart
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
        $data = $Script:data | Select-Object -ExpandProperty $dataChart.path `
                                              -Unique -ErrorAction SilentlyContinue | Select-Object -ExpandProperty data `
                                              | Group-Object $dataChart.data -ErrorAction SilentlyContinue

        if($null -ne $data){
            $dataSets = @()
            $labels = New-Object System.Collections.Generic.List[string]
            foreach($elem in $data){
                $hashTable = [System.Collections.Specialized.OrderedDictionary]::new()
                $outHashTable = [System.Collections.Specialized.OrderedDictionary]::new()
                #check if property exists
                $property_exists = [bool]($elem.Group | Get-Member -Name $dataChart.groupby)
                if($property_exists){
                    $chart_results = $elem.Group | Group-Object -Property $dataChart.groupby | Select-Object name, count
                    $chart_results = Update-ChartData -chartData $chart_results
                    $values = New-Object System.Collections.Generic.List[string]
                    $chart_results | ForEach-Object {$values.Add($_.count)}
                    $chart_results | ForEach-Object {$hashTable.Add($_.Name,$_.Count)}
                    $chart_results | ForEach-Object {$labels.Add($_.name)}
                    $outHashTable.Add("label",$elem.Name)
                    $outHashTable.Add("data",$values)
                    #$outHashTable.Add("hashtable",$hashTable)
                    if($dataChart.dataSet){
                        $ht2 = @{}
                        $dataChart.dataSet.psobject.properties | ForEach-Object { $ht2[$_.Name] = $_.Value }
                        $outHashTable = Merge-HashTable -default $outHashTable -uppend $ht2
                    }
                    $dataSets+=$outHashTable
                }
                else{
                    Write-Warning ($script:messages.UnableToGetProperty -f $dataChart.groupby)
                }
            }
        }
        else{
            Write-Warning ($script:messages.UnknownPath -f $dataChart.path)
        }
    }
    End{
        if($dataSets -and $Labels){
            #Add labels to chart
            $jsonChart.data.labels = ($Labels | Select-Object -Unique)
            #Set chart type
            $jsonChart.type = $dataChart.chartType
            #set chart options
            if($null -ne $dataChart.PSObject.Properties.Item('options') -and $dataChart.options){
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
