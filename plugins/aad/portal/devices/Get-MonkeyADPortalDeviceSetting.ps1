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


function Get-MonkeyADPortalDeviceSetting {
<#
        .SYNOPSIS
		Plugin to get device settings from Azure AD

        .DESCRIPTION
		Plugin to get device settings from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADPortalDeviceSetting
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
			Id = "aad0026";
			Provider = "AzureAD";
			Resource = "AzureADPortal";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyADPortalDeviceSetting";
			ApiType = "AzureADPortal";
			Title = "Plugin to get device settings from Azure AD";
			Group = @("AzureADPortal");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD device settings",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalDevices');
		}
		Write-Information @msg
		#Get Device Settings
		$params = @{
			Authentication = $AADAuth;
			Query = 'DeviceSetting';
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
            InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$azure_ad_device_settings = Get-MonkeyAzurePortalObject @params
	}
	end {
		if ($azure_ad_device_settings) {
			$azure_ad_device_settings.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.DeviceSettings')
			[pscustomobject]$obj = @{
				Data = $azure_ad_device_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_device_settings = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD device settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalDevicesEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




