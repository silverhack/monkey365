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


function Get-MonkeyAZApplicationGateway {
<#
        .SYNOPSIS
		Collector to get info regarding application gateway from Azure

        .DESCRIPTION
		Collector to get info regarding application gateway from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZApplicationGateway
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
			Id = "az00060";
			Provider = "Azure";
			Resource = "ApplicationGateway";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZApplicationGateway";
			ApiType = "resourceManagement";
			description = "Collector to get information from Azure Application Gateway";
			Group = @(
				"ApplicationGateway"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_app_gateway"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$AzureAPPGTWConfig = $O365Object.internal_config.ResourceManager.Where({ $_.Name -eq "azureAppGateway" }) | Select-Object -ExpandProperty resource
		#Get application gateways
		$app_gateways = $O365Object.all_resources.Where({ $_.type -eq 'Microsoft.Network/applicationGateways' });
		#Set null
		$all_appGateways = $null
	}
	process {
		if ($app_gateways.Count -gt 0) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure application gateway",$O365Object.current_subscription.displayName);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureAppGatewayInfo');
			}
			Write-Information @msg
			$new_arg = @{
				APIVersion = $AzureAPPGTWConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyApplicationGatewayInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$all_appGateways = $app_gateways | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($null -ne $all_appGateways) {
			$all_appGateways.PSObject.TypeNames.Insert(0,'Monkey365.Azure.application_gateways')
			[pscustomobject]$obj = @{
				Data = $all_appGateways;
				Metadata = $monkey_metadata;
			}
			$returnData.az_app_gateway = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure application gateway",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureAppGatewayEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}


