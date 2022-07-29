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

function Remove-ExcelObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Remove-ExcelObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    if($null -ne (Get-Variable -Name ExcelComObj -Scope Script -ErrorAction Ignore)){
        try{
            $Script:ExcelComObj.DisplayAlerts = $false
		    $Script:ExcelComObj.ActiveWorkBook.Close | Out-Null
		    $Script:ExcelComObj.Quit()
            #Release Object
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Script:ExcelComObj) | Out-Null
            #$ExcelComObj = $null
		    #$WorkBook = $null
            #Remove vars
            Remove-Variable -Name ExcelComObj -Scope Script -Force -ErrorAction Ignore
            Remove-Variable -Name WorkBook -Scope Script -Force -ErrorAction Ignore
		    [GC]::Collect()
		    [GC]::WaitForPendingFinalizers()
            #Clean up
            if($null -ne (Get-Variable -Name postExcelProcesses -Scope Script -ErrorAction Ignore) -and $null -ne (Get-Variable -Name priorExcelProcesses -Scope Script -ErrorAction Ignore)){
                $Script:postExcelProcesses | Where-Object {$null -eq $Script:existingExcelProcesses -or $Script:priorExcelProcesses -notcontains $_ } | ForEach-Object { Stop-Process -Id $_ }
                #Remove vars
                Remove-Variable -Name existingExcelProcesses -Scope Script -Force -ErrorAction Ignore
                Remove-Variable -Name postExcelProcesses -Scope Script -Force -ErrorAction Ignore
            }
        }
        catch{
            Write-Verbose $_.Exception
        }
    }
}
