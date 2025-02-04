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

Function Get-MonkeyAzApplicationGatewayWAFPolicy {
    <#
        .SYNOPSIS
		Get Application Gateway WAF Policy

        .DESCRIPTION
		Get Application Gateway WAF Policy

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzApplicationGatewayWAFPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Application Gateway object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-02-01"
    )
    Process{
        try{
            $wafPolicies = $managedRules = $null;
            $fwPolicyId = $InputObject.properties.firewallPolicy.id;
            if($fwPolicyId){
                $p = @{
	                Id = $fwPolicyId;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $wafPolicies = Get-MonkeyAzObjectById @p
                #Get location
                $location = $wafPolicies.location;
                if($null -ne $location){
                    #Get Managed rules
                    $p = @{
	                    Environment = $O365Object.Environment;
                        Provider = 'Microsoft.Network';
                        ObjectType = ("locations/{0}/applicationGatewayWafDynamicManifests" -f $location);
                        ApiVersion = $APIVersion;
                        Authentication = $O365Object.auth_tokens.ResourceManager;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $managedRules = Get-MonkeyRMObject @p
                }
            }
            #Get managed rules
            if($null -ne $managedRules -and $null -ne $wafPolicies){
                $appliedPolicies = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                $rulesets = $wafPolicies.properties.managedRules.managedRuleSets
                foreach($ruleset in $rulesets){
                    $appliedRuleset = $managedRules.properties.availableRuleSets.Where({$_.rulesetType -eq $ruleset.ruleSetType -and $_.ruleSetVersion -eq $ruleset.ruleSetVersion})
                    if($appliedRuleset.Count -gt 0){
                        [void]$appliedPolicies.AddRange($appliedRuleset);
                    }
                }
                #populate object
                $InputObject.wafPolicies.Name = $wafPolicies.name;
                $InputObject.wafPolicies.id = $wafPolicies.id;
                $InputObject.wafPolicies.location = $wafPolicies.location;
                $InputObject.wafPolicies.policySettings = $wafPolicies.properties.policySettings;
                $InputObject.wafPolicies.managedRules = $appliedPolicies;
                $InputObject.wafPolicies.properties = $wafPolicies.properties;
                $InputObject.wafPolicies.rawData = $wafPolicies;
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}

