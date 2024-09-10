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

        [parameter(Mandatory=$False, HelpMessage="Rules Path")]
        [String]$RulesPath,

        [Parameter(Mandatory=$false, HelpMessage="Set the output timestamp format as unix timestamps instead of iso format")]
        [Switch]$UnixTimestamp
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
    }
    Process{
        if(($Rule | Test-isValidRule) -and $null -ne (Get-Variable -Name Dataset -ErrorAction Ignore)){
            $ShadowRule = $Rule | Copy-PsObject
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
                if($null -ne $findingObj){
                    if(!$matched_elements){
                        $findingObj.level = "Good"
                    }
                    #Add status code
                    $findingObj.statusCode = $findingObj.level | Get-StatusCode
                    Write-Output $findingObj
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