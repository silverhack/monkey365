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

function New-ExcelChart{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-ExcelChart
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Work sheet")]
        [Object]$WorkSheet,

        [parameter(Mandatory=$True, HelpMessage="Data range")]
        [Object]$DataRange,

        [parameter(Mandatory=$True, HelpMessage="ChartType")]
        [String]$chartType,

        [parameter(Mandatory=$false, HelpMessage="Has datatable")]
        [Switch]$HasDataTable,

        [parameter(Mandatory=$false, HelpMessage="Style")]
        [Int]$Style,

        [parameter(Mandatory=$false, HelpMessage="Chart title")]
        [String]$ChartTitle,

        [parameter(Mandatory=$false, HelpMessage="Save image")]
        [Switch]$saveImage,

        [parameter(Mandatory=$false, HelpMessage="Position")]
        [Object]$Position
    )
    Begin{
        #Add Types
		#Add-Type -AssemblyName Microsoft.Office.Interop.Excel
		$MyChartType=[Microsoft.Office.Interop.Excel.XLChartType]$chartType
        # Add the chart
	    $Chart = $WorkSheet.Shapes.AddChart().Chart
	    $Chart.ChartType = $MyChartType
	    #$Chart | gm
        #check chartType
        if (-not $PSBoundParameters.ContainsKey('chartType')) {
            $chartType = 'xlColumnClustered'
        }
    }
    Process{
        # Apply a specific style for each type
	    If( $ChartType -like "xlPie" ){
		    # http://msdn.microsoft.com/fr-fr/library/microsoft.office.interop.excel._chart.setsourcedata(v=office.11).aspx
		    $Chart.SetSourceData($DataRange)
	    }
        else{
		    $Chart.SetSourceData($DataRange,[Microsoft.Office.Interop.Excel.XLRowCol]::xlRows)
		    $Chart.ChartStyle = $Style
		    if ($HasDataTable){
			    $Chart.HasDataTable = $true
			    $Chart.DataTable.HasBorderOutline = $true
                $NbSeries = $Chart.SeriesCollection().Count
		        # Define data labels
		        for ( $i=1 ; $i -le $NbSeries; ++$i ){
			        $Chart.SeriesCollection($i).HasDataLabels = $true
			        $Chart.SeriesCollection($i).DataLabels(0).Position = 3
                }
            }
		    $Chart.HasAxis([Microsoft.Office.Interop.Excel.XlAxisType]::xlCategory) = $false
		    $Chart.HasAxis([Microsoft.Office.Interop.Excel.XlAxisType]::xlValue) = $false
	    }
        #Set ChartTitle
        if ($ChartTitle){
		    $Chart.HasTitle = $true
			$Chart.ChartTitle.Text = $ChartTitle
		}
        #Set layout and position
        #http://msdn.microsoft.com/en-us/library/office/bb241345(v=office.12).aspx
        $Chart.ApplyLayout(2,$Chart.ChartType)
		$Chart.Legend.Position = -4107
    }
    End{
        #Extract Row $ Col
        #$Row=$Position[0]
        $Col = $Position[1]
        #Get Range
        #$ChartRange = $WorkSheet.Range($WorkSheet.Cells.Item(1,$col),$WorkSheet.Cells.Item(18,6))
        [void]$WorkSheet.Range($WorkSheet.Cells.Item(1,$col),$WorkSheet.Cells.Item(18,6))
        # Define the position of the chart
	    $ChartObj = $Chart.Parent
        $ChartObj.Height = $DataRange.Height * 4
	    $ChartObj.Width = $DataRange.Width + 100
        $ChartObj.Top = $DataRange.Top
	    $ChartObj.Left = $DataRange.Left
        #Save image
        If($saveImage){
		    $ImageFile = ($env:temp + "\" + ([System.Guid]::NewGuid()).ToString() + ".png")
			$Chart.Export($ImageFile)
			return $ImageFile
		}
    }
}
