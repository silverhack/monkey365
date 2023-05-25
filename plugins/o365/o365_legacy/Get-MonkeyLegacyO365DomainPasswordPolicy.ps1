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


function Get-MonkeyLegacyO365DomainPasswordPolicy {
<#
        .SYNOPSIS
		Plugin to get information about domain password policy using legacy O365 API

        .DESCRIPTION
		Plugin to get information about domain password policy using legacy O365 API

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyLegacyO365DomainPasswordPolicy
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
			Id = "aadl002";
			Provider = "AzureAD";
			Resource = "LegacyO365API";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyLegacyO365DomainPasswordPolicy";
			ApiType = "LegacyO365API";
			Title = "Plugin to get information about domain password policy using legacy O365 API";
			Group = @("LegacyO365API");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Domain password policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('LegacyDomainPasswordPolicyInfo');
		}
		Write-Information @msg
		$domain_password_policy = Get-MonkeyMsolDomainPasswordPolicy
	}
	end {
		if ($domain_password_policy) {
			$domain_password_policy.PSObject.TypeNames.Insert(0,'Monkey365.Legacy.DomainPasswordPolicy')
			[pscustomobject]$obj = @{
				Data = $domain_password_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_domain_password_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Domain password policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('LegacyDomainPasswordPolicyEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




