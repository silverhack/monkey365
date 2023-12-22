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

Function Resolve-Include{
    <#
        .SYNOPSIS
        Resolve include query

        .DESCRIPTION
        Resolve include query

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-Include
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True,HelpMessage="Statement")]
        [Object]$Statement
    )
    try{
        $includeFile = $Statement.include
        $isRoot = [System.IO.Path]::IsPathRooted($includeFile);
        if($isRoot){
            if([System.IO.File]::Exists($includeFile)){
                try{
                    $new_condition = (Get-Content $includeFile -Raw) | ConvertFrom-Json
                    ConvertTo-Query -Conditions $new_condition
                }
                catch{
                    Write-Warning $_.Exception.Message
                    Write-Verbose $_.Exception
                }
            }
            else{
                Write-Warning ("The file {0} does not exists" -f $includeFile)
            }
        }
        else{
            if($null -ne (Get-Variable -Name ConditionsPath -Scope Script -ErrorAction Ignore)){
                $rule = Get-File -FileName $includeFile -Rulepath $Script:ConditionsPath
                if($rule){
                    try{
                        $new_condition = (Get-Content $rule.FullName -Raw) | ConvertFrom-Json
                        ConvertTo-Query -Conditions $new_condition
                    }
                    catch{
                        Write-Warning $_.Exception.Message
                        Write-Verbose $_.Exception
                    }
                }
            }
            else{
                Write-Warning ("Unable to resolve include file {0}" -f $includeFile)
            }
        }
    }
    catch{
        Write-Error $_
    }
}
