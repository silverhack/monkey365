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

Function Get-AvailableRule{
    <#
        .SYNOPSIS
        Get status of available rules. If dataset is not present, the rule won't be executed. When used with Invoke-RuleScan, this function will remove unused rules

        .DESCRIPTION
        Get status of available rules. If dataset is not present, the rule won't be executed. When used with Invoke-RuleScan, this function will remove unused rules

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AvailableRule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PsObject]])]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Status")]
        [Switch]$Status
    )
    Try{
        If($null -ne (Get-Variable -Name AllRules -Scope Script -ErrorAction Ignore) -and $null -ne (Get-Variable -Name Dataset -Scope Script -ErrorAction Ignore)){
            #Create new array
            $formattedRules = [System.Collections.Generic.List[System.Management.Automation.PsObject]]::new()
            #create PsObject for every rule indicating if should be skipped or not
            Foreach($rule in $Script:AllRules){
                #Create PsObject
                $ruleObj = [PsCustomObject]@{
                    displayName = $rule.displayName;
                    path = $null;
                    idSuffix = $rule.idSuffix;
                    provider = $rule.provider;
                    service = $rule.serviceType;
                    skipped = $null;
                    reason = $null;
                    rule = ($rule | Copy-PsObject);
                    manual = $null;
                }
                #Check if rule has a query
                $definedQuery = Get-ObjectPropertyByPath -InputObject $rule -Property "rule.query"
                If($null -eq $definedQuery){
                    $ruleObj.manual = $true
                }
                Else{
                    $ruleObj.manual = $false
                }
                #Select path
                $_path = $rule.rule | Select-Object -ExpandProperty path | Select-Object -Unique
                $exists = $Script:Dataset | Select-Object -ExpandProperty $_path -ErrorAction Ignore
                If($exists){
                    $ruleObj.path = $_path;
                    $ruleObj.skipped = $false;
                    $ruleObj.reason = "Data exists in dataset";
                }
                Else{
                    #removing rule
                    Write-Verbose -Message ($Script:messages.UnitItemNotFound -f $rule.displayName)
                    $ruleObj.path = $_path;
                    $ruleObj.skipped = $true;
                    $ruleObj.reason = "Data is not present in dataset";
                }
                #Add to array
                $formattedRules.Add($ruleObj)
            }
            If($Status.IsPresent){
                $formattedRules | Select-Object displayName,skipped,reason,manual,provider,service
            }
            Else{
                $formattedRules.Where({$_.skipped -eq $false})
            }
        }
    }
    Catch{
        Write-Error $_
    }
}

