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


Function Get-MonkeyMSGraphAuthorizationPolicy{
    <#
        .SYNOPSIS
		Get authorization policy

        .DESCRIPTION
		Get authorization policy

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAuthorizationPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
	Param (
        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    try{
        #Set var
        $auth_policy = [PsCustomObject]@{
            tenantAuthPolicy = $null;
            tenantAuthPolicyId = $null;
            tenantFlowsPolicy = $null;
            tenantFlowsPolicyId = $null;
        }
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $params = @{
            Authentication = $graphAuth;
            ObjectType = "policies/authorizationPolicy";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $tenant_auth_policy = Get-MonkeyMSGraphObject @params
        If($APIVersion.ToLower() -eq 'beta'){
            #normalize data to match with V1.0
            $permissionGrant = $tenant_auth_policy | Select-Object -ExpandProperty permissionGrantPolicyIdsAssignedToDefaultUserRole -ErrorAction Ignore
            If ($null -ne $permissionGrant){
                $tenant_auth_policy.defaultUserRolePermissions | Add-Member -MemberType NoteProperty -Name permissionGrantPoliciesAssigned -Value $permissionGrant -Force
            }
        }
        #Add to Object
        If($tenant_auth_policy){
            $auth_policy.tenantAuthPolicy = $tenant_auth_policy;
            $auth_policy.tenantAuthPolicyId = $tenant_auth_policy.id;
        }
        #Get flows policy
        $params = @{
            Authentication = $graphAuth;
            ObjectType = "policies/authenticationFlowsPolicy";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $tenant_flows_policy = Get-MonkeyMSGraphObject @params
        #Add to object
        If($tenant_flows_policy){
            $auth_policy.tenantFlowsPolicy = $tenant_flows_policy;
            $auth_policy.tenantFlowsPolicyId = $tenant_flows_policy.id;
        }
        return $auth_policy
    }
    catch{
        $msg = @{
            MessageData = "Unable to get authorization policies";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $O365Object.InformationAction;
            Tags = @('AzureGraphAuthorizationPolicyError');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        [void]$msg.Add('verbose',$O365Object.verbose)
        Write-Verbose @msg
    }
}

