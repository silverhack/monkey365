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


function Get-MonkeyAzDiagnosticSetting {
<#
        .SYNOPSIS
		Plugin to get diagnostic settings for each resource in Azure

        .DESCRIPTION
		Plugin to get diagnostic settings for each resource in Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzDiagnosticSetting
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
			Id = "az00018";
			Provider = "Azure";
			Title = "Plugin to get diagnostic settings for Azure resources";
			Group = @("DiagnosticSettings","General");
			ServiceName = "Azure Diagnostic Settings";
			PluginName = "Get-MonkeyAzDiagnosticSetting";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		$all_diag_settings = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Diagnostic settings",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureDiagSettingsInfo');
		}
		Write-Information @msg
		foreach ($resource in $O365Object.all_resources) {
			$params = @{
				objectId = $resource.id;
				resource = "providers/microsoft.insights/diagnosticSettings";
				api_version = "2017-05-01-preview";
			}
			$diag_settings = Get-MonkeyRmObjectById @params
			if ($diag_settings) {
				$resource | Add-Member -Type NoteProperty -Name diagnostic_settings -Value $diag_settings
			}
			else {
				$resource | Add-Member -Type NoteProperty -Name diagnostic_settings -Value $null
			}
			$all_diag_settings += $resource
		}
		#Check if diagnostic settings captures appropriate categories
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Diagnostic settings global configuration",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureDiagGlobalSettingsInfo');
		}
		Write-Information @msg
		$uri = ('/subscriptions/{0}' -f $O365Object.current_subscription.subscriptionId)
		$params = @{
			objectId = $uri;
			resource = "providers/microsoft.insights/diagnosticSettings";
			api_version = "2017-05-01-preview";
		}
		$diag_global_settings = Get-MonkeyRmObjectById @params
	}
	end {
		if ($all_diag_settings) {
			$all_diag_settings.PSObject.TypeNames.Insert(0,'Monkey365.Azure.DiagnosticSettings')
			[pscustomobject]$obj = @{
				Data = $all_diag_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.az_diagnostic_settings = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Diagnostic Settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureDiagSettingsEmptyResponse');
			}
			Write-Warning @msg
		}
		if ($diag_global_settings) {
			$diag_global_settings.PSObject.TypeNames.Insert(0,'Monkey365.Azure.DiagnosticSettingsGlobalConfig')
			[pscustomobject]$obj = @{
				Data = $diag_global_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.az_diagnostic_settings_config = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Diagnostic Settings global configuration",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureDiagSettingsGlobalEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
