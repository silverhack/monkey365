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

Function Get-ElementsToCheck{
    <#
        .SYNOPSIS
        Get elements to check from dataset

        .DESCRIPTION
        Get elements to check from dataset

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ElementsToCheck
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Object path")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$Path
    )
    Process{
        try{
            if($null -ne (Get-Variable -Name Dataset -Scope Script -ErrorAction Ignore)){
                if([String]::IsNullOrEmpty($Path) -or [String]::IsNullOrWhiteSpace($Path)){
                    $Script:Dataset
                }
                elseif($path.Trim().ToString().Contains('.')){
                    if(($Script:Dataset.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
                        $Script:Dataset.GetPropertyByPath($Path.Trim())
                    }
                    else{
                        Write-Warning "GetPropertyByPath method was not loaded"
                    }
                }
                else{
                    #Get element
                    $Script:Dataset | Select-Object -ExpandProperty $Path.Trim() -ErrorAction Ignore #| Select-Object -ExpandProperty Data -ErrorAction SilentlyContinue
                }
            }
            else{
                Write-Warning "Dataset was not set"
            }
        }
        catch{
            Write-Error $_
        }
    }
}