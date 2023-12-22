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


function Get-MonkeyADAuthenticationMethodsPolicy {
<#
        .SYNOPSIS
		Collector to get Authentication method policies from Microsoft Entra ID

        .DESCRIPTION
		Collector to get Authentication method policies from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADAuthenticationMethodsPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		$Environment = $O365Object.Environment
		#Collector metadata
		$monkey_metadata = @{
			Id = "aad0020";
			Provider = "EntraID";
			Resource = "EntraIDPortal";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyADAuthenticationMethodsPolicy";
			ApiType = "EntraIDPortal";
			description = "Collector to get Authentication method policies from Microsoft Entra ID";
			Group = @(
				"EntraIDPortal"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"aad_authentication_policy"
			);
			dependsOn = @(

			);
		}
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
		<#
            Type 8 == Microsoft Authenticator
            Type 6 == FIDO2
            Type 5 == SMS Preview
            Type 9 == Temporary access pass

            state:0 == enabled
            state:1 == disabled
        #>
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID authentication policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalAuthPolicy');
		}
		Write-Information @msg
		#Query
		$params = @{
			Authentication = $AADAuth;
			Query = 'AuthenticationMethods/AuthenticationMethodsPolicy';
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$ad_authentication_policy = Get-MonkeyAzurePortalObject @params
	}
	end {
		if ($ad_authentication_policy) {
			$ad_authentication_policy.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.AuthenticationPolicy')
			[pscustomobject]$obj = @{
				Data = $ad_authentication_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_authentication_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID authentication policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalAuthPolicyEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







