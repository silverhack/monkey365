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

Function Invoke-RuleScan{
    <#
        .SYNOPSIS
        Scan a dataset with a number of rules

        .DESCRIPTION
        Scan a dataset with a number of rules

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-RuleScan
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Dataset")]
        [Object]$InputObject,

        [parameter(Mandatory=$True, ParameterSetName = 'RuleSet', HelpMessage="Ruleset File")]
        [String]$Ruleset,

        [parameter(Mandatory=$True, ParameterSetName = 'RuleSetObject', HelpMessage="Ruleset Object File")]
        [Object]$RulesetObject,

        [parameter(Mandatory=$False, HelpMessage="Rules Path")]
        [String]$RulesPath,

        [Parameter(Mandatory=$false, HelpMessage="Set the output timestamp format as unix timestamps instead of iso format")]
        [Switch]$UnixTimestamp
    )
    Begin{
        $validRules = $null;
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        #Get Initialize-MonkeyRuleset params
        $newPsboundParams = [ordered]@{}
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Initialize-MonkeyRuleset")
        if($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters.Item($p))
                }
            }
        }
        #Initialize ruleset
        $isActive = Initialize-MonkeyRuleset @newPsboundParams
        if($isActive){
            New-Variable -Name Dataset -Value $InputObject -Scope Script -Force
            $p = @{
                InformationAction = $InformationAction;
                Verbose = $Verbose;
                Debug = $Debug;
            }
            $validRules = Get-ValidRule @p
        }
    }
    Process{
        if($null -ne $validRules -and @($validRules).Count -gt 0){
            foreach($rule in @($validRules)){
                #Build query
                $rule = $rule | Build-Query
                If($null -ne $rule){
                    #Get element
                    $ObjectsToCheck = $rule | Get-ObjectFromDataset
                    If($null -ne $ObjectsToCheck){
                        $matched_elements = $rule | Invoke-UnitRule -ObjectsToCheck $ObjectsToCheck
                    }
                    Else{
                        Write-Warning ("{0} was not found on dataset or query was invalid" -f $rule.rule.path)
                        continue
                    }
                    #Check for removeIfNotExists exception rule
                    $removeIfNotExists = $rule.rule | Select-Object -ExpandProperty removeIfNotExists -ErrorAction Ignore
                    If($null -ne $removeIfNotExists -and $removeIfNotExists){
                        If($null -eq $matched_elements){
                            continue
                        }
                    }
                    $p =  @{
                        InputObject = $rule;
                        AffectedObjects = $matched_elements;
                        Resources = $ObjectsToCheck;
                        UnixTimestamp = $PSBoundParameters['UnixTimestamp'];
                    }
                    $findingObj = New-MonkeyFindingObject @p
                    if(!$matched_elements){
                        $findingObj.level = "Good"
                    }
                    #Add status code
                    $findingObj.statusCode = $findingObj.level | Get-StatusCode
                    Write-Output $findingObj
                }
            }
        }
    }
    End{
    }
}