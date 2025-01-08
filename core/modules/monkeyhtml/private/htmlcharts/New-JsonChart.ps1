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

Function New-JsonChart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-JsonChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Array]$chartData,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$chartType,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Array]$backgroundColor,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Array]$hoverBackgroundColor,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Array]$borderColor,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Array]$legendColor,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [int32]$pointRadius,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [int32]$borderWidth,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [int32]$barThickness,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [int32]$maxBarThickness,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Array]$labels,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Array]$nested_labels,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.Collections.Hashtable]$options,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$external_options
    )
    Begin{
        $jsonChart = [ordered]@{
            type = $chartType
            data = @{
                labels = $labels
                datasets = @()
            }
            options = @{}
        }
        #Check if flatten or jagged array
        if($chartData.Length -gt 0 -and $chartData.GetValue(0) -is [array]){
            $flatten = $false
        }
        else{
            $flatten = $True
        }
    }
    Process{
        if($flatten -eq $True){
            $dataset = @{
                data = $chartData;
            }
            if($backgroundColor){
                $dataset.Add('backgroundColor',$backgroundColor)
            }
            if($barThickness){
                $dataset.Add('barThickness',$barThickness)
            }
            if($maxBarThickness){
                $dataset.Add('maxBarThickness',$maxBarThickness)
            }
            if($borderColor){
                $dataset.Add('borderColor',$borderColor)
            }
            if($hoverBackgroundColor){
                $dataset.Add('hoverBackgroundColor',$hoverBackgroundColor)
            }
            if($legendColor){
                $dataset.Add('legendColor',$legendColor)
            }
            if($pointRadius){
                $dataset.Add('pointRadius',$pointRadius)
            }
            else{
                $dataset.Add('pointRadius',0)
            }
            if($borderWidth){
                $dataset.Add('borderWidth',$borderWidth)
            }
            #Add to main dict
            $jsonChart.data.datasets= @($dataset)
        }
        elseif($flatten -eq $false){
            Write-Verbose $script:messages.DetectedNonFlattenArray
            for ($i=0; $i -lt $chartData.Count; $i++){
                $dataset = @{
                    data = $chartData[$i];
                }
                if($backgroundColor){
                    $dataset.Add('backgroundColor',$backgroundColor[$i])
                }
                if($borderColor){
                    $dataset.Add('borderColor',$borderColor[$i])
                }
                if($hoverBackgroundColor){
                    $dataset.Add('hoverBackgroundColor',$hoverBackgroundColor[$i])
                }
                if($barThickness){
                    $dataset.Add('barThickness',$barThickness)
                }
                if($maxBarThickness){
                    $dataset.Add('maxBarThickness',$maxBarThickness)
                }
                if($legendColor){
                    $dataset.Add('legendColor',$legendColor[$i])
                }
                if($pointRadius){
                    $dataset.Add('pointRadius',$pointRadius)
                }
                if($nested_labels){
                    $dataset.Add('label',$nested_labels[$i])
                }
                if($borderWidth){
                    $dataset.Add('borderWidth',$borderWidth)
                }
                #Add to main dict
                $jsonChart.data.datasets+= $dataset
            }
        }
        #Check if options
        if($options){
            #set chart options
            $jsonChart.options = $options
        }
        elseif($external_options){
            $jsonChart.options = '${external_options}'
        }
        else{
            #remove options
            $jsonChart.Remove('options')
        }
        #convertto JSON
        $jsonChart = $jsonChart | ConvertTo-Json -Depth 5
        #check if extra options
        if($external_options){
            $jsonChart = $jsonChart -replace '"\${external_options}"', $external_options
        }
    }
    End{
        return $jsonChart
    }
}

