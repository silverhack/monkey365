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

function Get-Condition{
    <#
        .SYNOPSIS
        Get a hashtable with valid conditions from object

        .DESCRIPTION
        Get a hashtable with valid conditions from object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-Condition
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Conditions")]
        [Object]$Condition
    )
    Process{
        try{
            #Get RightToleft
            $RightToLeft = $Condition | Select-Object -ExpandProperty rightToLeft -ErrorAction Ignore
            $RightToLeft = Convert-Value -Value $RightToLeft
            if($null -eq $RightToLeft -or $RightToLeft -isnot [bool]){
                $RightToLeft = $false;
            }
            $conditionht = [ordered]@{
                Conditions = $Condition | Select-Object -ExpandProperty conditions -ErrorAction Ignore
                Operator = $Condition | Select-Object -ExpandProperty operator -ErrorAction Ignore
                LogicalNotOperator = $Condition | Select-Object -ExpandProperty logicalNot -ErrorAction Ignore
                RightToLeft = $RightToLeft
            }
            if($null -ne $conditionht.Conditions){
                return $conditionht
            }
            else{
                Write-Warning "Unable to get conditions"
            }
        }
        catch{
            Write-Error $_
        }
    }
}