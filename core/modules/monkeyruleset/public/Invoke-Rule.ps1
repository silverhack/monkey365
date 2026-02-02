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

Function Invoke-Rule{
    <#
        .SYNOPSIS
        Scan a dataset with a rule

        .DESCRIPTION
        Scan a dataset with a rule

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-Rule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$False, ValueFromPipeline = $True, HelpMessage="Dataset")]
        [Object]$InputObject,

        [parameter(Mandatory=$True, HelpMessage="Rule Object")]
        [Object]$Rule,

        [parameter(Mandatory=$False, HelpMessage="Rule arguments")]
        [System.Array]$Arguments,

        [parameter(Mandatory=$False, HelpMessage="Rule displayName")]
        [System.String]$DisplayName,

        [parameter(Mandatory=$False, HelpMessage="Rule description")]
        [System.String]$Description,

        [parameter(Mandatory=$False, HelpMessage="Rule impact")]
        [System.String]$Impact,

        [parameter(Mandatory=$False, HelpMessage="Rule remediation")]
        [System.String]$Remediation,

        [parameter(Mandatory=$False, HelpMessage="Rule rationale")]
        [System.String]$Rationale,

        [parameter(Mandatory=$False, HelpMessage="Rule references")]
        [System.Array]$References,

        [parameter(Mandatory=$False, HelpMessage="Rule level")]
        [System.String]$Level,

        [parameter(Mandatory=$False, HelpMessage="Rule compliance")]
        [Object]$Compliance,

        [parameter(Mandatory=$False, HelpMessage="Rules Path")]
        [String]$RulesPath,

        [Parameter(Mandatory=$false, HelpMessage="Set the output timestamp format as unix timestamps instead of iso format")]
        [Switch]$UnixTimestamp,

        [Parameter(Mandatory=$false, HelpMessage="Convert pass finding to good finding")]
        [Switch]$ConvertPassFindingToGood
    )
    Begin{
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        If($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        If($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        If($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        If($PSBoundParameters.ContainsKey('InputObject') -and $PSBoundParameters['InputObject']){
            $InputObject | New-Dataset
        }
        If($PSBoundParameters.ContainsKey('RulesPath')){
            $PSBoundParameters['RulesPath'] | Set-InternalVar
        }
        #Get Initialize-MonkeyRuleset params
        $newPsboundParams = [ordered]@{}
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Update-MonkeyRule")
        If($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys
            ForEach($p in $param.GetEnumerator()){
                If($p.ToLower() -eq 'inputobject'){
                    continue
                }
                If($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters.Item($p))
                }
            }
        }
    }
    Process{
        If(($Rule | Test-isValidRule) -and $null -ne (Get-Variable -Name Dataset -ErrorAction Ignore)){
            #First update rule with potential parameters, such as displayName, level, etc..
            $Rule = $Rule | Update-MonkeyRule @newPsboundParams
            If($null -ne $Rule){
                $ShadowRule = $Rule | Copy-PsObject
                #Check if rule has a query
                $definedQuery = Get-ObjectPropertyByPath -InputObject $ShadowRule -Property "rule.query"
                If($null -eq $definedQuery){
                    #Query is empty. Set rule as a manual
                    $p =  @{
                        InputObject = $ShadowRule;
                        AffectedObjects = $null;
                        Resources = $null;
                        UnixTimestamp = $PSBoundParameters['UnixTimestamp'];
                    }
                    $findingObj = New-MonkeyFindingObject @p
                    If($null -ne $findingObj){
                        #Add status code
                        $findingObj.statusCode = "manual"
                        Write-Output $findingObj
                    }
                }
                Else{
                    $ShadowRule = $ShadowRule | Build-Query
                    #Find elements to check
                    $ObjectsToCheck = $ShadowRule | Get-ObjectFromDataset
                    If($null -eq $ObjectsToCheck){
                        return
                    }
                    #Get objects to check
                    If($null -ne $ShadowRule){
                        #$matched_elements = $ShadowRule | Invoke-UnitRule -ObjectsToCheck $dataObjects
                        $matched_elements = $ShadowRule | Invoke-UnitRule -ObjectsToCheck $ObjectsToCheck
                    }
                    Else{
                        Write-Warning -Message ($Script:messages.InvalidQueryGenericMessage -f $Rule.displayName)
                        $matched_elements = $null
                    }
                    #Check for removeIfNotExists exception rule
                    $removeIfNotExists = $ShadowRule.rule | Select-Object -ExpandProperty removeIfNotExists -ErrorAction Ignore
                    If($null -ne $removeIfNotExists -and $removeIfNotExists){
                        If($null -eq $matched_elements){
                            return
                        }
                    }
                    If($null -ne $ShadowRule){
                        #Create finding object
                        $p =  @{
                            InputObject = $ShadowRule;
                            AffectedObjects = $matched_elements;
                            Resources = $ObjectsToCheck;
                            UnixTimestamp = $PSBoundParameters['UnixTimestamp'];
                        }
                        $findingObj = New-MonkeyFindingObject @p
                        If($null -ne $findingObj){
                            If($PSBoundParameters.ContainsKey('ConvertPassFindingToGood') -and $PSBoundParameters['ConvertPassFindingToGood'].IsPresent){
                                If(!$matched_elements){
                                    $findingObj.level = "Good"
                                }
                            }
                            #Add status code
                            If($matched_elements){
                                $findingObj.statusCode = "fail"
                            }
                            Else{
                                $findingObj.statusCode = "pass"
                            }
                            Write-Output $findingObj
                        }
                    }
                }
            }
        }
        Else{
            Write-Warning $Script:messages.InvalidObject
        }
    }
    End{
        #Nothing to do here
    }
}
