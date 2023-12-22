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


function Get-MonkeyADConnectInfo {
<#
        .SYNOPSIS
		Collector to get Microsoft Entra ID connect information

        .DESCRIPTION
		Collector to get Microsoft Entra ID connect information

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADConnectInfo
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
		#Collector metadata
		$monkey_metadata = @{
			Id = "aad0036";
			Provider = "EntraID";
			Resource = "EntraIDPortal";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyADConnectInfo";
			ApiType = "EntraIDPortal";
			description = "Collector to get Microsoft Entra ID connect information";
			Group = @(
				"EntraIDPortal"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"aad_connect_info"
			);
			dependsOn = @(

			);
		}
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
		#Set dict
		$ad_connect_dict = [ordered]@{
			ADConnect = $null;
			PasswordSync = $null;
			SeamlessSignOn = $null;
			PassThroughAuth = $null;
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID Connect Info",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzurePortalConnectInfo');
		}
		Write-Information @msg
		#Get AD connect status
		$params = @{
			Authentication = $AADAuth;
			Query = "Directories/ADConnectStatus";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$ad_connect_info = Get-MonkeyAzurePortalObject @params
		if ($ad_connect_info) {
			$ad_connect_dict.ADConnect = $ad_connect_info
		}
		#Get AD connect password synchronization
		$params = @{
			Authentication = $AADAuth;
			Query = "Directories/GetPasswordSyncStatus";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$ad_passSync_info = Get-MonkeyAzurePortalObject @params
		if ($ad_passSync_info) {
			$ad_connect_dict.PasswordSync = $ad_passSync_info
		}
		#Get AD connect seamless sign on
		$params = @{
			Authentication = $AADAuth;
			Query = "Directories/GetSeamlessSingleSignOnDomains";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$ad_seamless_info = Get-MonkeyAzurePortalObject @params
		if ($ad_seamless_info) {
			$ad_connect_dict.SeamlessSignOn = $ad_seamless_info
		}
		#Get AD connect pass through auth
		$params = @{
			Authentication = $AADAuth;
			Query = "Directories/PassThroughAuthConnectorGroups";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$ad_passthroug_info = Get-MonkeyAzurePortalObject @params
		if ($ad_passthroug_info) {
			$ad_connect_dict.PassThroughAuth = $ad_passthroug_info
		}
	}
	end {
		if ($null -ne $ad_connect_dict) {
			#Convert to PsObject
			$adObject = New-Object -TypeName PsObject -Property $ad_connect_dict
			$adObject.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.connect.info')
			[pscustomobject]$obj = @{
				Data = $adObject;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_connect_info = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID Connect Info",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalConnectEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







