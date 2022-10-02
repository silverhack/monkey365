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


function Get-MonkeyADDirectoryProperty {
<#
        .SYNOPSIS
		Plugin to get directory properties from Azure AD

        .DESCRIPTION
		Plugin to get directory properties from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADDirectoryProperty
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
			Id = "aad0027";
			Provider = "AzureAD";
			Title = "Plugin to get directory properties from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD Directory Properties";
			PluginName = "Get-MonkeyADDirectoryProperty";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
		#Query
		$params = @{
			Authentication = $AADAuth;
			Query = $null;
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD directory properties",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalDirectoryProperties');
		}
		Write-Information @msg
		#Get directory properties
		$params.Query = "Directories/Properties"
		$azure_ad_directory_properties = Get-MonkeyAzurePortalObject @params
		#Get Azure AD default directory properties
		$params.Query = "Directory"
		$azure_ad_default_directory_properties = Get-MonkeyAzurePortalObject @params
		#Get Azure B2B directory properties
		$params.Query = "Directories/B2BDirectoryProperties"
		$azure_ad_b2b_directory_properties = Get-MonkeyAzurePortalObject @params
		#Get Azure B2B directory policy
		$params.Query = "B2B/b2bPolicy"
		$azure_ad_b2b_directory_policies = Get-MonkeyAzurePortalObject @params
	}
	end {
		#Return directory properties
		if ($azure_ad_directory_properties) {
			$azure_ad_directory_properties.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.directory.properties')
			[pscustomobject]$obj = @{
				Data = $azure_ad_directory_properties;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_directory_properties = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD directory properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalEmptyResponse');
			}
			Write-Warning @msg
		}
		#Return default directory properties
		if ($azure_ad_default_directory_properties) {
			$azure_ad_default_directory_properties.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.default.directory.properties')
			[pscustomobject]$obj = @{
				Data = $azure_ad_default_directory_properties;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_default_directory_props = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD default directory properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalEmptyResponse');
			}
			Write-Warning @msg
		}
		#Return b2b directory properties
		if ($azure_ad_b2b_directory_properties) {
			$azure_ad_b2b_directory_properties.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.b2b.directory.properties')
			[pscustomobject]$obj = @{
				Data = $azure_ad_b2b_directory_properties;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_b2b_directory_properties = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD B2B properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalEmptyResponse');
			}
			Write-Warning @msg
		}
		#Return b2b directory policies
		if ($azure_ad_b2b_directory_policies) {
			$azure_ad_b2b_directory_policies.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.b2b.directory.policies')
			[pscustomobject]$obj = @{
				Data = $azure_ad_b2b_directory_policies;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_b2b_directory_policies = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD B2B directory properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
