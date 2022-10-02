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


function Get-MonkeyADGroupConfiguration {
<#
        .SYNOPSIS
		Plugin to get group settings from Azure AD

        .DESCRIPTION
		Plugin to get group settings from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADGroupConfiguration
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
		$Environment = $O365Object.Environment
		#Plugin metadata
		$monkey_metadata = @{
			Id = "aad0029";
			Provider = "AzureAD";
			Title = "Plugin to get group settings from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD Group settings";
			PluginName = "Get-MonkeyADGroupConfiguration";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD group settings",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalGroupSettings');
		}
		Write-Information @msg
		#Get Device Settings
		$params = @{
			Authentication = $AADAuth;
			Query = 'Directories/SsgmProperties';
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
		}
		$azure_ad_group_settings = Get-MonkeyAzurePortalObject @params
	}
	end {
		if ($azure_ad_group_settings) {
			$azure_ad_group_settings.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.GroupSettings')
			[pscustomobject]$obj = @{
				Data = $azure_ad_group_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_group_settings = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD group settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalGroupEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
