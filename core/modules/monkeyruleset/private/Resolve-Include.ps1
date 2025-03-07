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
        [parameter(Mandatory=$True, ValueFromPipeline = $True,HelpMessage="Include Object")]
        [Object]$InputObject
    )
    Process{
        $ruleObj = $null;
        $includeFile = $InputObject.include
        $isRoot = [System.IO.Path]::IsPathRooted($includeFile);
        If($isRoot){
            If([System.IO.File]::Exists($includeFile)){
                #Get rule file object
                try{
                    $ruleObj = (Get-Content $includeFile -Raw) | ConvertFrom-Json
                }
                Catch{
                    Write-Warning $_.Exception.Message
                    Write-Verbose $_.Exception
                }
            }
            Else{
                Write-Warning -Message ($Script:messages.FileNotFoundGenericMessage -f $includeFile)
            }
        }
        Else{
            If($null -ne (Get-Variable -Name ConditionsPath -Scope Script -ErrorAction Ignore)){
                Try{
                    $rule = Get-File -FileName $includeFile -Rulepath $Script:ConditionsPath
                    $ruleObj = (Get-Content $rule.FullName -Raw) | ConvertFrom-Json
                }
                Catch{
                    Write-Warning $_.Exception.Message
                    Write-Verbose $_.Exception
                }
            }
            Else{
                Write-Warning -Message ($Script:messages.IncludeObjectErrorMessage -f $includeFile)
            }
        }
        #Evaluate condition
        If($null -ne $ruleObj){
            #Set stringBuilder
            $finalquery = [System.Text.StringBuilder]::new()
            #Convert to query
            $newQuery = $ruleObj | ConvertTo-Query
            foreach($q in @($newQuery)){
                [void]$finalquery.Append((" {0}" -f $q));
            }
            If($finalquery.Length -gt 0){
                $finalquery.ToString()
            }
        }
    }
}

