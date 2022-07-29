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

Function Add-TrafficLightsIcon{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Add-TrafficLightsIcon
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Alias('Sheet')]
        [String]$SheetName,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Alias('Column')]
        [String]$ColumnName
    )
    Begin{
        try{
            #Charts Variables
		    $xlConditionValues=[Microsoft.Office.Interop.Excel.XLConditionValueTypes]
		    $xlIconSet=[Microsoft.Office.Interop.Excel.XLIconSet]
		    $xlDirection=[Microsoft.Office.Interop.Excel.XLDirection]
            if(Get-Variable -Name ExcelComObj -Scope Script -ErrorAction SilentlyContinue){
		        $MyWorkSheet = $ExcelComObj.WorkSheets.Item($SheetName)
		        $Headers = Read-WorkSheetHeaders $MyWorkSheet
            }
            else{
                $Headers = $null
                $MyWorkSheet = $null
            }
        }
        catch{
            Write-Warning $_.Exception
            $Headers = $null
            $MyWorkSheet = $null
        }
    }
    Process{
        #Add Icons
        if($null -ne $Headers -and $null -ne $MyWorkSheet){
            try{
		        $range = [char]($Headers[$ColumnName]+64)
		        $start=$WorkSheet.range($range+"2")
		        #get the last cell
		        $Selection=$WorkSheet.Range($start,$start.End($xlDirection::xlDown))
            }
            catch{
                Write-Warning $_.Exception
                $Selection = $null
                break
            }
        }
    }
    End{
        if($null -ne $Selection){
            #add the icon set
		    [void]$Selection.FormatConditions.AddIconSetCondition()
		    [void]$Selection.FormatConditions.item($($Selection.FormatConditions.Count)).SetFirstPriority()
		    $Selection.FormatConditions.item(1).ReverseOrder = $True
		    $Selection.FormatConditions.item(1).ShowIconOnly = $True
		    $Selection.FormatConditions.item(1).IconSet = $xlIconSet::xl3TrafficLights1
		    $Selection.FormatConditions.item(1).IconCriteria.Item(2).Type=$xlConditionValues::xlConditionValueNumber
		    $Selection.FormatConditions.item(1).IconCriteria.Item(2).Value=60
		    $Selection.FormatConditions.item(1).IconCriteria.Item(2).Operator=7
		    $Selection.FormatConditions.item(1).IconCriteria.Item(3).Type=$xlConditionValues::xlConditionValueNumber
		    $Selection.FormatConditions.item(1).IconCriteria.Item(3).Value=90
		    $Selection.FormatConditions.item(1).IconCriteria.Item(3).Operator=7
        }
    }
}
