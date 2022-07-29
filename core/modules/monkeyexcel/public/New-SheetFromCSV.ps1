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

function New-SheetFromCSV{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-SheetFromCSV
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Raw data")]
        [Alias('MyData')]
        [Object]$Data,

        [parameter(Mandatory=$True, HelpMessage="Sheet name")]
        [Alias('SheetName')]
        [String]$Title,

        [parameter(Mandatory=$false, HelpMessage="Table name")]
        [Alias('TableName')]
        [String]$TableTitle,

        [parameter(Mandatory=$false, HelpMessage="Style")]
        [Alias('Style')]
        [String]$TableStyle,

        [parameter(Mandatory=$false, HelpMessage="Column name")]
        [Alias('ColumnName')]
        [String]$iconColumnName,

        [parameter(Mandatory=$false, HelpMessage="Freeze pane")]
        [Switch]$Freeze
    )
    Begin{
        try{
            if ($null -ne $Data -and $Title){
                #Create tmp file and store all content
                $CSVFile = ($env:temp + "/" + ([System.Guid]::NewGuid()).ToString() + ".csv")
			    $Data | Export-Csv -path $CSVFile -noTypeInformation -ErrorAction SilentlyContinue
                #Create new Sheet in Excel
                $workSheet = New-WorkSheet -Title $Title -RemoveGridLines
            }
        }
        catch{
            Write-Warning $_.Exception
        }
    }
    Process{
        if($null -ne $workSheet){
            #Define the connection string and where the data is supposed to go
			$TxtConnector = ("TEXT;" + $CSVFile)
			$CellRef = $workSheet.Range("A1")
            #Build, use and remove the text file connector
			$Connector = $workSheet.QueryTables.add($TxtConnector,$CellRef)
			$workSheet.QueryTables.item($Connector.name).TextFileCommaDelimiter = $True
			$workSheet.QueryTables.item($Connector.name).TextFileParseType  = 1
			[void]$workSheet.QueryTables.item($Connector.name).Refresh()
			[void]$workSheet.QueryTables.item($Connector.name).delete()
			[void]$workSheet.UsedRange.EntireColumn.AutoFit()
            $listObject = $workSheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::xlSrcRange,`
                            $workSheet.UsedRange, $null,[Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes,$null)
			if($listObject -and $TableTitle){
                $listObject.Name = $TableTitle
            }
            if($listObject -and $TableStyle){
                # Style Cheat Sheet: https://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet.tablestyle.aspx
                # Table styles https://msdn.microsoft.com/en-us/library/office/dn535872.aspx
			    $listObject.TableStyle = $TableStyle
            }
            [void]$workSheet.Activate();
			$workSheet.Application.ActiveWindow.SplitRow = 1;
            if($Freeze){
			    $workSheet.Application.ActiveWindow.FreezePanes = $True
            }
            else{
                $workSheet.Application.ActiveWindow.FreezePanes = $false
            }
        }
    }
    End{
        if($CSVFile){
            #Remove Tmp file
            Remove-Item -Path $CSVFile -Force
        }
        if($iconColumnName -and $null -ne $workSheet){
            #Add TrafficLights icon to Column
			Add-TrafficLightsIcon -SheetName $Title -ColumnName $iconColumnName
        }
    }
}
