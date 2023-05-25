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


function Get-MonkeyAZSecCenterConfig {
<#
        .SYNOPSIS
		Azure plugin to get Microsoft Defender for Cloud settings

        .DESCRIPTION
		Azure plugin to get Microsoft Defender for Cloud settings

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZSecCenterConfig
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
			Id = "az00033";
			Provider = "Azure";
			Resource = "DefenderForCloud";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAZSecCenterConfig";
			ApiType = "resourceManagement";
			Title = "Plugin to get settings from Microsoft Defender for Cloud";
			Group = @("DefenderForCloud");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Microsoft Defender for Cloud Config
		$AzureSecCenterConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "securityCenter" } | Select-Object -ExpandProperty resource
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Microsoft Defender for Cloud Configuration",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureSecCenterInfo');
		}
		Write-Information @msg
		$URI = ("{0}{1}/providers/microsoft.Security/Settings?api-Version={2}" `
 				-f $O365Object.Environment.ResourceManager,$O365Object.current_subscription.Id,$AzureSecCenterConfig.api_version)

		$params = @{
			Authentication = $rm_auth;
			OwnQuery = $URI;
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
		}
		$sec_center_config = Get-MonkeyRMObject @params
	}
	end {
		if ($sec_center_config) {
			$sec_center_config.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SecurityCenter.Config')
			[pscustomobject]$obj = @{
				Data = $sec_center_config;
				Metadata = $monkey_metadata;
			}
			$returnData.az_security_center_config = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Defender for Cloud",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureSecCenterEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




