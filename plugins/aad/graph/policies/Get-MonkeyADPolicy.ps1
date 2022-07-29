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



Function Get-MonkeyADPolicy{
    <#
        .SYNOPSIS
		Plugin to get policies from Azure AD
        https://msdn.microsoft.com/en-us/library/azure/ad/graph/api/policy-operations

        .DESCRIPTION
		Plugin to get policies from Azure AD
        https://msdn.microsoft.com/en-us/library/azure/ad/graph/api/policy-operations

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        $api_version = $O365Object.internal_config.azuread.api_version
        #Check auth requestor
        if($O365Object.isConfidentialApp -eq $false){
            #Probably interactive user. Can use internal graph api
            $api_version = '1.6-internal'
        }
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure AD policies", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphPolicies');
        }
        Write-Information @msg
        #Get policies
        $URI = ("{0}/myorganization/policies?api-version={1}" -f $Environment.Graph, `
                                                                $api_version)
        #Get policies
        $params = @{
            Authentication = $AADAuth;
            OwnQuery = $URI;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
        }
        $all_policies = Get-MonkeyGraphObject @params
        #Convert definition and key credentials
        if($all_policies){
            foreach ($policy in $all_policies){
                if($policy.definition){
                    $policy.definition = (@($policy.definition) -join ',')
                }
                if($policy.keyCredentials){
                    $policy.keyCredentials = (@($policy.keyCredentials) -join ',')
                }
                if($policy.policyDetail){
                    $details = $policy.policyDetail[0] | ConvertFrom-Json
                    $policy.policyDetail = $details
                }
            }
        }
    }
    End{
        if($all_policies){
            $all_policies.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.Policies')
            [pscustomobject]$obj = @{
                Data = $all_policies
            }
            $returnData.aad_domain_policies = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD Policies", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphPoliciesEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
