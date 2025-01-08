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

Function ConvertTo-SecureScriptBlock{
    <#
        .SYNOPSIS
        Create a new secure ScriptBlock

        .DESCRIPTION
        Create a new secure ScriptBlock

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-SecureScriptBlock
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("InjectionRisk.Create", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ScriptBlock])]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Query string")]
        [String]$InputObject
    )
    Process{
        try{
            $allowed = @(
                'Isplit','imatch','Inotmatch',
                'Ireplace','Cmatch','Cnotmatch',
                'Creplace','Csplit','match','notmatch'
            )
            #Commands are not allowed
            $allowedCmds = [string[]] @()
            #Environment variables are not allowed
            $allowEnvVars= $false
            # Any variable will be allowed
            $allowedVariables = [string[]] @('*')
            #Remove Property references
            $sbTest = $InputObject.Replace('.','')
            foreach($allow in $allowed){
                if([regex]::isMatch($sbTest.ToLower(),("-{0}" -f $allow.ToLower()))){
                    $sbTest = $sbTest -ireplace [regex]::Escape($allow), "eq"
                }
            }
            #Replace Where if any
            $sbTest = $sbTest.Replace('Where', ' -and ').Replace('{','').Replace('}','')
            #Create an scriptblock that will not be executed
            $ScriptBlock = [scriptblock]::Create($sbTest)
            try{
                [void]$ScriptBlock.CheckRestrictedLanguage($allowedCmds, $allowedVariables, $allowEnvVars)
                return [ScriptBlock]::Create($InputObject)
            }
            catch{
                Write-Verbose $_.Exception.Message
                Write-Warning ($Script:messages.UnableToConvertToScriptBlock -f $InputObject.ToString())
            }
        }
        catch{
            Write-Error $_
        }
    }
}
