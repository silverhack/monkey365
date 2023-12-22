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

function Test-IsNullPsObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-IsNullPsObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Object to check")]
        [AllowNull()]
        [Object]$InputObject
    )
    Process{
        if ($null -eq $InputObject){
            return $true
        }
        ElseIf ($InputObject.GetType() -eq [System.Management.Automation.PSCustomObject] -or $InputObject.GetType() -eq [System.Management.Automation.PSObject]) {
            $numberOfElements = $InputObject.PsObject.Properties.Name.Count
            $countOfNull = 0
            foreach($elem in $InputObject.Psobject.Properties){
                if($null -eq $elem.Value){
                    $countOfNull+=1
                }
            }
            if($countOfNull -eq $numberOfElements){
                return $true
            }
            else{
                return $false
            }
        }
        else{
            Write-Warning "Unrecognized Object"
            return $true
        }
    }
}
