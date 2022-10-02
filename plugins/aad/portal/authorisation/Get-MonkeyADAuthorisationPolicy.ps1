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


function Get-MonkeyADAuthorisationPolicy {
<#
        .SYNOPSIS
		Plugin to get password reset policy from Azure AD

        .DESCRIPTION
		Plugin to get password reset policy from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADAuthorisationPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {

		#Plugin metadata
		$monkey_metadata = @{
			Id = "aad0003";
			Provider = "AzureAD";
			Title = "Plugin to get password reset policy from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD SSPR";
			PluginName = "Get-MonkeyADAuthorisationPolicy";
			Docs = "https://silverhack.github.io/monkey365/"
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD authorisation policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('GraphAuthPolicy');
		}
		Write-Information @msg
		#Query
		$ad_auth_policy = Get-PSGraphAuthorizationPolicy @params
	}
	end {
		if ($ad_auth_policy) {
			$ad_auth_policy.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.AuthorisationPolicy')
			[pscustomobject]$obj = @{
				Data = $ad_auth_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_auth_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD authorisation policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('GraphAuthPolicyEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
