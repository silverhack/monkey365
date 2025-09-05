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

Function Test-IsCustomFunction{
    <#
        .SYNOPSIS
        Check if ScriptBlock content contains a custom function

        .DESCRIPTION
        Check if ScriptBlock content contains a custom function

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-IsCustomFunction
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$true, HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock
    )
    Begin{
    }
    Process{
        Try{
            $tokenized = Get-TokenizedObject @PSBoundParameters
            #Group objects
            If($null -ne $tokenized){
                #If Param() is found then is a custom function
                If(@($tokenized).Where({$_.Type -eq "Keyword"}).Count -ge 1){
                    $True
                }
                #If more than 2 commands then is treated as a custom function
                ElseIf(@($tokenized).Where({$_.Type -eq "Command"}).Count -ge 3){
                    $True
                }
                #If more than 2 newLine then is treated as a custom function
                ElseIf(@($tokenized).Where({$_.Type -eq "NewLine"}).Count -gt 2){
                    $True
                }
                Else{
                    $false
                }
            }
        }
        Catch{
            Write-Error $_
            return $null
        }
    }
}
