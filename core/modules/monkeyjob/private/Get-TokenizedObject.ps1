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

Function Get-TokenizedObject{
    <#
        .SYNOPSIS
        Get tokenized object from ScriptBlock

        .DESCRIPTION
        Get tokenized object from ScriptBlock

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-TokenizedObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSToken]])]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$true, HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock
    )
    Begin{
        $errors = [System.Management.Automation.PSParseError[]] @()
    }
    Process{
        Try{
            [Management.Automation.PsParser]::Tokenize($ScriptBlock.tostring(), [ref] $errors)# | Where-Object {$_.Type -ne 'NewLine' -and  $_.Type -ne 'Comment'}
        }
        Catch{
            Write-Error $_
            return $null
        }
    }
}
