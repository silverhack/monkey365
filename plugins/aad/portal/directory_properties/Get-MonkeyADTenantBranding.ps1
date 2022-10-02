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


function Get-MonkeyADTenantBranding {
<#
        .SYNOPSIS
		Plugin to get tenant branding configuration from Azure AD

        .DESCRIPTION
		Plugin to get tenant branding configuration from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADTenantBranding
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
		$aad_company_branding = $null
		#Plugin metadata
		$monkey_metadata = @{
			Id = "aad0028";
			Provider = "AzureAD";
			Title = "Plugin to get tenant branding configuration from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD Tenant Branding";
			PluginName = "Get-MonkeyADTenantBranding";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD Company branding",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalTenantBranding');
		}
		Write-Information @msg
		#Get tenant branding
		$params = @{
			Authentication = $AADAuth;
			Query = "LoginTenantBrandings";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
		}
		$aad_company_branding = Get-MonkeyAzurePortalObject @params
	}
	end {
		#Return company branding
		if ($aad_company_branding) {
			$aad_company_branding.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.company.branding')
			[pscustomobject]$obj = @{
				Data = $aad_company_branding;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_company_branding = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD Company branding",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
