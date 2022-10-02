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


function Get-MonkeyADTenantInfo {
<#
        .SYNOPSIS
		Plugin to get tenant info from Azure AD

        .DESCRIPTION
		Plugin to get tenant info from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADTenantInfo
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
		$ad_tenant_info = $null
		#Plugin metadata
		$monkey_metadata = @{
			Id = "aad0035";
			Provider = "AzureAD";
			Title = "Plugin to get tenant info from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD Tenant information";
			PluginName = "Get-MonkeyADTenantInfo";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD Tenant Info",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalTenantInfo');
		}
		Write-Information @msg
		#Get Tenant Info
		$params = @{
			Authentication = $AADAuth;
			Query = "TenantSkuInfo";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
		}
		#Get tenant info
		$ad_tenant_info = Get-MonkeyAzurePortalObject @params
	}
	end {
		if ($null -ne $ad_tenant_info) {
			$ad_tenant_info.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.tenant.info')
			[pscustomobject]$obj = @{
				Data = $ad_tenant_info;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_tenant_info = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD Tenant Info",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalTenantEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
