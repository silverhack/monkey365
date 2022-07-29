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

function Save-Excel{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Save-Excel
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Out File')]
        [String]$outFile,

        [Parameter(Mandatory = $true, HelpMessage = 'Avoid displaying alerts to force saving Excel file')]
        [Switch]$Force
    )
    try{
        if($null -ne (Get-Variable -Name WorkBook -Scope Script -ErrorAction Ignore)){
            if($Force){
                $Script:ExcelComObj.DisplayAlerts = $false;
            }
            # http://msdn.microsoft.com/en-us/library/bb241279.aspx
            $xlFileFormat = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlWorkbookDefault
            $WorkBook.SaveAs($outFile.ToString(),$xlFileFormat)
            $WorkBook.Saved = $true;
            #Set displayAlerts True
            $Script:ExcelComObj.DisplayAlerts = $True;
        }
    }
    catch{
        Write-Warning $_
        Write-Debug $_.Exception
    }
}
