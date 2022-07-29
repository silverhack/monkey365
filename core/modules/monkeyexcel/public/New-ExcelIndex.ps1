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

Function New-ExcelIndex{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-ExcelIndex
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Front logo")]
        [String]$LogoFront,

        [parameter(Mandatory=$false, HelpMessage="Top left logo")]
        [String]$LogoTopLeft,

        [parameter(Mandatory=$false, HelpMessage="Username")]
        [String]$UserName
    )
    Begin{
        #Set Constants
        Set-Variable msoFalse 0 -Option Constant -ErrorAction SilentlyContinue
        Set-Variable msoTrue 1 -Option Constant -ErrorAction SilentlyContinue
        Set-Variable cellWidth 48 -Option Constant -ErrorAction SilentlyContinue
        Set-Variable cellHeight 15 -Option Constant -ErrorAction SilentlyContinue
    }
    Process{
        try{
            $WorkSheet = $null
            #Main Report Index
		    $row = 07
		    $col = 1
            if($null -ne (Get-Variable -Name WorkBook -ErrorAction Ignore)){
		        $WorkSheet = $WorkBook.WorkSheets.Add()
		        $WorkSheet.Name = "Index"
		        $WorkSheet.Tab.ColorIndex = 8
                foreach ($Sheet in $WorkBook.WorkSheets){
				    #$v = $WorkSheet.Hyperlinks.Add($WorkSheet.Cells.Item($row,$col),"","'$($_.Name)'"+"!$($r)","","$($_.Name)")
                    [void]$WorkSheet.Hyperlinks.Add($WorkSheet.Cells.Item($row,$col),"","'$($Sheet.Name)'"+"!A1","",$Sheet.Name)
				    $row++
                }
                $CellRange = $WorkSheet.Range("A1:A140")
		        #$CellRange.Interior.ColorIndex = 9
		        $CellRange.Font.ColorIndex = 9
                $CellRange.Font.Size = 14
		        $CellRange.Font.Bold = $true
		        [void]$WorkSheet.columns.item("A").EntireColumn.AutoFit()
                if($null -ne (Get-Variable -Name ExcelComObj -ErrorAction Ignore)){
		            $ExcelComObj.ActiveWindow.Displaygridlines = $false
                }
            }
        }
        catch{
            Write-Warning $_.Exception
        }

        # add image to the Sheet
        #Image format and properties
        if($null -ne $WorkSheet){
            $LinkToFile = $msoFalse
            $SaveWithDocument = $msoTrue
            $Left = 370
            $Top = 150
            $Width = 400
            $Height = 400
            if($LogoFront){
                [void]$WorkSheet.Shapes.AddPicture(
                            $LogoFront,
                            $LinkToFile,
                            $SaveWithDocument,
                            $Left,
                            $Top,
                            $Width,
                            $Height
                        )
            }

            # add image to the Sheet
            #Image format and properties
            $LinkToFile = $msoFalse
            $SaveWithDocument = $msoTrue
            $Left = 0
            $Top = 0
            $Width = 70
            $Height = 70
            if($LogoTopLeft){
                [void]$WorkSheet.Shapes.AddPicture($LogoTopLeft,
                                                    $LinkToFile,
                                                    $SaveWithDocument,
                                                    $Left,
                                                    $Top,
                                                    $Width,
                                                    $Height)
            }
        }
    }
    End{
        #Add UserName
        if($UserName -and $null -ne $WorkSheet){
            $WorkSheet.Cells.Item(5,1).Value() = $UserName
            $WorkSheet.Cells.Item(5,1).Font.Bold = $true
        }
    }
}
