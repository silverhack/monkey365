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


function Get-MonkeyCopilotForAzurePolicy {
<#
        .SYNOPSIS
		Collector to get information about Copilot for Azure

        .DESCRIPTION
		Collector to get information about Copilot for Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCopilotForAzurePolicy
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
			Id = "az00043";
			Provider = "Azure";
			Resource = "Copilot";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyCopilotForAzurePolicy";
			ApiType = "resourceManagement";
			description = "Collector to get information about Copilot for Azure";
			Group = @(
				"Subscription";
				"General"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_copilot_for_azure"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Copilot for Azure",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureSubscriptionCopilotInfo');
		}
		Write-Information @msg
		#Get Copilot For Azure
		$p = @{
			Id = 'providers/Microsoft.PortalServices/copilotSettings/default';
			APIVersion = '2024-04-01-preview';
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
			InformationAction = $O365Object.InformationAction;
		}
		$copilotInfo = Get-MonkeyAzObjectById @p
	}
	end {
		if ($copilotInfo) {
			$copilotInfo.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Copilot')
			[pscustomobject]$obj = @{
				Data = $copilotInfo;
				Metadata = $monkey_metadata;
			}
			$returnData.az_copilot_for_azure = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Copilot for Azure",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureSubscriptionCopilotEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}
