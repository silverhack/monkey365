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

function New-HashTableToWorkSheet{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HashTableToWorkSheet
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Raw data")]
        [HashTable]$Data,

        [parameter(Mandatory=$false, HelpMessage="Headers")]
        [Array]$Headers,

        [parameter(Mandatory=$false, HelpMessage="Sheet name")]
        [String]$SheetName,

        [parameter(Mandatory=$false, HelpMessage="Table name")]
        [String]$TableName,

        [parameter(Mandatory=$false, HelpMessage="Table format")]
        [String]$FormatTable,

        [parameter(Mandatory=$false, HelpMessage="Position")]
        [Array]$Position,

        [parameter(Mandatory=$false, HelpMessage="Show headers")]
        [Switch]$ShowHeaders,

        [parameter(Mandatory=$false, HelpMessage="Add chart")]
        [Switch]$AddNewChart,

        [parameter(Mandatory=$false, HelpMessage="Chart type")]
        [String]$ChartType,

        [parameter(Mandatory=$false, HelpMessage="Excel Debug")]
        [String]$HeaderStyle,

        [parameter(Mandatory=$false, HelpMessage="Header style")]
        [Switch]$HasDataTable,

        [parameter(Mandatory=$false, HelpMessage="Remove grid lines")]
        [Switch]$RemoveGridLines,

        [parameter(Mandatory=$false, HelpMessage="Chart style")]
        [Int]$ChartStyle,

        [parameter(Mandatory=$false, HelpMessage="Chart title")]
        [String]$ChartTitle,

        [parameter(Mandatory=$false, HelpMessage="Show details")]
        [Switch]$ShowTotals
    )
    Begin{
        if($SheetName){
            $params = @{
                Title = $SheetName;
                RemoveGridLines = $RemoveGridLines;
            }
            #Create new worksheet
            $workSheet = New-WorkSheet @params
        }
        if($null -ne $workSheet){
            $Cells = $WorkSheet.Cells
		    $Row=$Position[0]
		    $InitialRow = $Row
		    $Col=$Position[1]
		    $InitialCol = $Col
            #Check for headers
            if ($Headers){
                #insert column headings
			    $Headers | ForEach-Object{
    					    $cells.item($row,$col)=$_
    					    $cells.item($row,$col).font.bold=$True
    					    $Col++
			    }
		    }
            # Add table content
		    foreach ($element in $Data.GetEnumerator()){
                $Row++
	    	    $Col = $InitialCol
	    	    $cells.item($Row,$Col) = $element.Name
                try{
                    $nbItems = @($element.Value).Count
                }
                catch{
                    $nbItems = 1
                }
                for ( $i=0; $i -lt $nbItems; $i++ ){
				    $Col++
	    		    $cells.item($Row,$Col) = $Data[$element.Name][$i]
	    		    $cells.item($Row,$Col).NumberFormat ="0"
			    }
            }
        }
    }
    Process{
        if($null -ne $workSheet){
            # Apply Styles to table
		    $Range = $WorkSheet.Range($WorkSheet.Cells.Item($InitialRow,$InitialCol),$WorkSheet.Cells.Item($Row,$Col))
		    $listObject = $worksheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::xlSrcRange, $Range, $null,[Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes,$null)
		    if($TableName){
                $listObject.Name = $TableName
            }
            if($ShowTotals){
		        $listObject.ShowTotals = $True
            }
            if($ShowHeaders){
		        $listObject.ShowHeaders = $True
            }
            # Style Cheat Sheet: https://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet.tablestyle.aspx
            # Table styles https://msdn.microsoft.com/en-us/library/office/dn535872.aspx
            if($FormatTable){
		        $listObject.TableStyle = $FormatTable
            }
            # Sort data based on the 2nd column
            $MyPosition = $WorkSheet.Cells.Item($InitialRow+1,$InitialCol+1).Address($False,$False)
		    $SortRange = $WorkSheet.Range($MyPosition) # address: Convert cells position 1,1 -> A:1
		    [void]$WorkSheet.Sort.SortFields.Clear()
		    [void]$WorkSheet.Sort.SortFields.Add($SortRange,0,1,0)
		    $WorkSheet.Sort.SetRange($Range)
		    $WorkSheet.Sort.Header = 1 # exclude header
		    $WorkSheet.Sort.Orientation = 1
		    [void]$WorkSheet.Sort.Apply()
            # Apply Styles to Title
		    $cells.item(1,$InitialCol) = $TableName
		    $RangeTitle = $WorkSheet.Range($WorkSheet.Cells.Item(1,$InitialCol),$WorkSheet.Cells.Item(1,$Col))
		    #$RangeTitle.MergeCells = $true
            if($HeaderStyle){
		        $RangeTitle.Style = $HeaderStyle
            }
		    # http://msdn.microsoft.com/en-us/library/microsoft.office.interop.excel.constants.aspx
		    $RangeTitle.HorizontalAlignment = -4108
		    $RangeTitle.ColumnWidth = 20
        }
    }
    End{
        #Add chart
        if($AddNewChart -and $ChartType){
            $params = @{
                DataRange = $Range;
                ChartType = $ChartType;
                ChartTitle = $ChartTitle;
                HasDataTable = $HasDataTable;
                Style = $ChartStyle;
                Position = $Position;
                WorkSheet = $workSheet;
            }
            New-ExcelChart @params
        }
    }
}
