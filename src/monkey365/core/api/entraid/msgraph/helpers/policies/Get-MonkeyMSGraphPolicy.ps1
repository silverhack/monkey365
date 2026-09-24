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

Function Get-MonkeyMSGraphPolicy {
    <#
        .SYNOPSIS
		Get Entra ID policies from Microsoft Graph

        .DESCRIPTION
		Get Entra ID policies from Microsoft Graph

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $false, HelpMessage= "Select an Entra ID Policy")]
        [ValidateSet("SecurityDefault","authorizationPolicy",
            "homeRealmDiscoveryPolicies","authenticationFlowsPolicy",
            "authenticationStrengthPolicies", "featureRolloutPolicies",
            "mfaServicePolicy","authenticationmethodspolicy"
        )]
        [String]$PolicyType= "SecurityDefault",

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        Switch($PolicyType.ToLower()){
            'securitydefault'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'identitySecurityDefaultsEnforcementPolicy';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'authorizationpolicy'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'authorizationPolicy';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'homerealmdiscoverypolicies'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'homeRealmDiscoveryPolicies';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'authenticationflowspolicy'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'authenticationFlowsPolicy';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'authenticationstrengthpolicies'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'authenticationStrengthPolicies';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'featurerolloutpolicies'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'featureRolloutPolicies';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'mfaservicepolicy'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'mfaServicePolicy';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'authenticationmethodspolicy'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'authenticationmethodspolicy';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            default{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies';
                    ObjectId = 'identitySecurityDefaultsEnforcementPolicy';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
        }
        Get-MonkeyMSGraphObject @p
    }
    End{
        #Nothing to do here
    }
}
