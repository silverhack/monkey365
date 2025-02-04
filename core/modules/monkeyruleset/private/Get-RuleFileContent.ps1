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

Function Get-RuleFileContent{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-RuleFileContent
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="File")]
        [Object]$InputObject
    )
    Process{
        $fContent = $null;
        Try{
            if($InputObject -isnot [System.IO.FileSystemInfo]){
                If ($InputObject.GetType() -eq [System.Management.Automation.PSCustomObject] -or $InputObject.GetType() -eq [System.Management.Automation.PSObject] -and $null -ne $InputObject.Psobject.Properties.Item('FullName')){
                    $fContent = (Get-Content $InputObject.FullName -Raw) | ConvertFrom-Json;
                }
                Else{
                    #Content is not valid
                    $fContent = $null;
                }
            }
            Else{
                $fContent = (Get-Content $InputObject.FullName -Raw) | ConvertFrom-Json;
            }
            #Test if content if valid content
            if ($null -ne $fContent -and ($fContent | Test-isValidRule)){
                $fContent | Add-Member -Type NoteProperty -name File -value $InputObject -Force;
                Write-Output $fContent
            }
        }
        Catch{
            Write-Error $_
        }
    }
}


