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
        $auth_policy = [ordered]@{
        }
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
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
        #Add to dict
        $auth_policy.Add('TenantAuthPolicy',$tenant_auth_policy)
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
        #Add to dict
        $auth_policy.Add('TenantFlowsPolicy',$tenant_flows_policy)
        $globalAuthPolicy = New-Object PSObject -Property $auth_policy
        return $globalAuthPolicy
    }
    catch{
        $msg = @{
            MessageData = "Unable to get authorization policies";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
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
