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

function New-ExcelObject{
    <#
        .SYNOPSIS
            Function to create a new COM Excel Object

        .EXAMPLE
	        New-ExcelObject -Visible
            This example will return a new Excel Object in Debug Mode (Visible)

        .EXAMPLE
	        New-ExcelObject
            This example will return a new Excel Object in normal mode (Invisible)

        .PARAMETER Debug
	        Determines whether the object is visible

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    [OutputType([System.Boolean])]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Excel Debug")]
        [Alias('OpenExcel')]
        [Switch]$Visible
    )
    Begin{
        try{
            #Check if can call to ComObject
            $command = Get-Command New-Object
            if($command.Parameters.ContainsKey('ComObject')){
                #Get PID for each Excel opened instance
                $existingExcelProcesses = Get-Process -name "*Excel*" | ForEach-Object { $_.Id }
                #Create Excel
	            [Threading.Thread]::CurrentThread.CurrentCulture = 'en-US'
	            $excel_app = New-Object -ComObject Excel.Application
                if($Visible){
	                $excel_app.visible = $true
                }
                $postExcelProcesses = Get-Process -name "*Excel*" | ForEach-Object { $_.Id }
            }
            else{
                Write-Warning -Message ($Script:messages.ExcelUnsupportedOSErrorMessage -f [System.Environment]::OSVersion.VersionString);
                $excel_app = $null
            }
        }
        catch{
            Write-Debug $_.Exception
            $excel_app = $null
        }
    }
    Process{
        if($null -ne $excel_app){
            $objWorkBook = $excel_app.WorkBooks.Add()
            if($excel_app.Version -le "14.0"){
                #Delete sheets for Office 2010
                1..2 | ForEach-Object {
	                $objWorkbook.WorkSheets.Item($_).Delete()
		        }
            }
        }
    }
    End{
        if($null -ne $excel_app){
            #Create vars for Excel formatting
            Set-Variable ExcelComObj -Value $excel_app -Scope Script -Force
            Set-Variable WorkBook -Value $objWorkBook -Scope Script -Force
            Set-Variable existingExcelProcesses -Value $existingExcelProcesses -Scope Script -Force
            Set-Variable postExcelProcesses -Value $postExcelProcesses -Scope Script -Force
            return $true
        }
        else{
            return $false
        }
    }
}
