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

Function Test-isValidRule{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-isValidRule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Rule object")]
        [Object]$InputObject
    )
    Process{
        Try{
            $missingElements = @()
            #Rule valid keys
            $properties = @(
                'serviceType',
                'serviceName',
                'displayName',
                'description',
                'rationale',
                'references',
                'idSuffix'
            )
            $inputProperties = $InputObject | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name -ErrorAction Ignore
            Foreach ($key in $properties){
                If ($key -in $inputProperties){
                    #passed test
                    continue;
                }
                Else{
                    #no element was found
                    $missingElements+=$key
                }
            }
            #Check if rule is present
            $ruleObj = $InputObject | Select-Object -ExpandProperty rule -ErrorAction Ignore
            If($null -eq $ruleObj){
                $missingElements+='rule'
            }
            If($missingElements.Count -eq 0){
                Write-Verbose ($Script:messages.ValidObjectMessage -f "rule")
                return $true
            }
            Else{
                $missing = @($missingElements) -join ','
                If($null -ne $InputObject.PsObject.Properties.Item('displayName')){
                    Write-Warning ($Script:messages.InvalidRuleMessage -f $InputObject.displayName)
                }
                Write-Warning ($Script:messages.MissingElementsMessage -f "rule", $missing)
                return $false
            }
        }
        Catch{
            Write-Error $_
            #Invalid rule
            return $false;
        }
    }
}

