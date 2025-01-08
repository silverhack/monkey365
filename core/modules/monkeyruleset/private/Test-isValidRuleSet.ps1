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

Function Test-isValidRuleSet{
    <#
        .SYNOPSIS
        Check if ruleset is valid

        .DESCRIPTION
        Check if ruleset is valid

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-isValidRuleSet
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Ruleset object")]
        [Object]$Object
    )
    Process{
        $missingElements = @();
        #Ruleset valid keys
        $skeleton = @(
            'about',
            'framework',
            'rules'
        )
        try{
            foreach ($key in $skeleton){
                if ($null -ne $Object.psObject.Properties.Item($key)){
                    #passed test
                    continue;
                }
                else{
                    #no element was found
                    $missingElements+=$key
                }
            }
        }
        catch{
            #Invalid rule
            return $false;
        }
        if($missingElements.Count -eq 0){
            Write-Verbose ($Script:messages.ValidObjectMessage -f "ruleset")
            return $true
        }
        else{
            $missing = @($missingElements) -join ','
            Write-Warning ($Script:messages.MissingElementsMessage -f "ruleset", $missing)
            return $false
        }
    }
}

