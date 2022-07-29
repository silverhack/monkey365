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

Function New-ExcelAbout{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-ExcelAbout
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Display name")]
        [String]$displayName,

        [parameter(Mandatory=$false, HelpMessage="HyperLinks")]
        [Array]$HyperLinks,

        [parameter(Mandatory=$false, HelpMessage="Company logo")]
        [String]$CompanyLogo,

        [parameter(Mandatory=$false, HelpMessage="Remove grid lines")]
        [Switch]$RemoveGridLines
    )
    Begin{
        #Main Report Index
		[Void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
		$WorkSheet = $WorkBook.WorkSheets.Add()
		$WorkSheet.Name = "About"
        if($displayName){
		    $WorkSheet.Cells.Item(1,1).Value() = $displayName
		    $WorkSheet.Cells.Item(1,1).Font.Size = 25
		    $WorkSheet.Cells.Item(1,1).Font.Bold = $true
        }
        $cnt = 1
        if($HyperLinks){
            foreach ($hyperLink in $HyperLinks){
		        $WorkSheet.Cells.Item(24+$cnt,4).Value() = $hyperLink
		        $r = $WorkSheet.Range("D"+(24+$cnt))
		        [void]$WorkSheet.Hyperlinks.Add($r,$hyperLink)
		        $WorkSheet.Cells.Item(24+$cnt,4).Font.Size = 14
		        $WorkSheet.Cells.Item(24+$cnt,4).Font.Bold = $true
                $cnt+=2
            }
        }
    }
    Process{
        #Set Constants
        Set-Variable msoFalse 0 -Option Constant -ErrorAction SilentlyContinue
        Set-Variable msoTrue 1 -Option Constant -ErrorAction SilentlyContinue

        Set-Variable cellWidth 48 -Option Constant -ErrorAction SilentlyContinue
        Set-Variable cellHeight 15 -Option Constant -ErrorAction SilentlyContinue
        if($CompanyLogo){
            #Image format and properties
            $LinkToFile = $msoFalse
            $SaveWithDocument = $msoTrue
            $Left = 400
            $Top = 40
            $Width = 400
            $Height = 400

            # add image to the Sheet
            [void]$WorkSheet.Shapes.AddPicture($CompanyLogo,
                                                $LinkToFile,
                                                $SaveWithDocument,
                                                $Left,
                                                $Top,
                                                $Width,
                                                $Height)
        }
    }
    End{
        #Remove GridLines
        if($RemoveGridLines){
            $Script:ExcelComObj.ActiveWindow.Displaygridlines = $false
            $CellRange = $WorkSheet.Range("A1:G30")
            #Color palette
            #http://dmcritchie.mvps.org/excel/colors.htm
		    #$CellRange.Interior.ColorIndex = 1
		    $CellRange.Font.ColorIndex = 30
        }
    }
}
