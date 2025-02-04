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
		Collector to get directory properties from Microsoft Entra ID

        .DESCRIPTION
		Collector to get directory properties from Microsoft Entra ID

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
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		$Environment = $O365Object.Environment
		#Collector metadata
		$monkey_metadata = @{
			Id = "aad0027";
			Provider = "EntraID";
			Resource = "EntraIDPortal";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyADDirectoryProperty";
			ApiType = "EntraIDPortal";
			description = "Collector to get directory properties from Microsoft Entra ID";
			Group = @(
				"EntraIDPortal"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_directory_properties";
				"aad_default_directory_props";
				"aad_b2b_directory_properties";
				"aad_b2b_directory_policies"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
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
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID directory properties",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalDirectoryProperties');
		}
		Write-Information @msg
		#Get directory properties
		$params.Query = "Directories/Properties"
		$azure_ad_directory_properties = Get-MonkeyAzurePortalObject @params
		#Get Microsoft Entra ID default directory properties
		$params.Query = "Directory"
		$azure_ad_default_directory_properties = Get-MonkeyAzurePortalObject @params
		#Get Azure B2B directory properties
		$params.Query = "Directories/B2BDirectoryProperties"
		$azure_ad_b2b_directory_properties = Get-MonkeyAzurePortalObject @params
		#Get Azure B2B directory policy
		$params.Query = "B2B/b2bPolicy"
		$azure_ad_b2b_directory_policies = Get-MonkeyAzurePortalObject @params
		#Mock b2b directory policy if not exists
		if ($null -eq $azure_ad_b2b_directory_policies) {
			$azure_ad_b2b_directory_policies = [pscustomobject]@{
				targetedDomains = @();
				hasListEntries = $false;
				adminConsentedForUsersIntoTenantIds = @();
				noAADConsentForUsersFromTenantsIds = @();
			}
		}
	}
	end {
		#Return directory properties
		if ($azure_ad_directory_properties) {
			$azure_ad_directory_properties.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.directory.properties')
			[pscustomobject]$obj = @{
				Data = $azure_ad_directory_properties;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_directory_properties = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID directory properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		#Return default directory properties
		if ($azure_ad_default_directory_properties) {
			$azure_ad_default_directory_properties.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.default.directory.properties')
			[pscustomobject]$obj = @{
				Data = $azure_ad_default_directory_properties;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_default_directory_props = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID default directory properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		#Return b2b directory properties
		if ($azure_ad_b2b_directory_properties) {
			$azure_ad_b2b_directory_properties.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.b2b.directory.properties')
			[pscustomobject]$obj = @{
				Data = $azure_ad_b2b_directory_properties;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_b2b_directory_properties = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID B2B properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		#Return b2b directory policies
		if ($azure_ad_b2b_directory_policies) {
			$azure_ad_b2b_directory_policies.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.b2b.directory.policies')
			[pscustomobject]$obj = @{
				Data = $azure_ad_b2b_directory_policies;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_b2b_directory_policies = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID B2B directory properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










