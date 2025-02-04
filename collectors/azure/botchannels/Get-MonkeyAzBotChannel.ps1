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




function Get-MonkeyAzBotChannel {
<#
        .SYNOPSIS
		Azure Bots
        https://docs.microsoft.com/en-us/azure/bot-service/dotnet/bot-builder-dotnet-security?view=azure-bot-service-3.0
        https://github.com/Azure/azure-rest-api-specs/blob/master/specification/botservice/resource-manager/Microsoft.BotService/preview/2017-12-01/botservice.json

        .DESCRIPTION
		Azure Bots
        https://docs.microsoft.com/en-us/azure/bot-service/dotnet/bot-builder-dotnet-security?view=azure-bot-service-3.0
        https://github.com/Azure/azure-rest-api-specs/blob/master/specification/botservice/resource-manager/Microsoft.BotService/preview/2017-12-01/botservice.json

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzBotChannel
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
			Id = "az00003";
			Provider = "Azure";
			Resource = "BotChannels";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzBotChannel";
			ApiType = "resourceManagement";
			description = "Collector to get information from Azure Bots";
			Group = @(
				"BotChannels"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_bots"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Config
		$AzureBot = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureBotServices" } | Select-Object -ExpandProperty resource
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Bots",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureBotsInfo');
		}
		Write-Information @msg
		#List All Azure Bots
		$params = @{
			Authentication = $rm_auth;
			Provider = $AzureBot.Provider;
			ObjectType = 'botServices';
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			APIVersion = $AzureBot.api_version;
		}
		$azureBots = Get-MonkeyRMObject @params
	}
	end {
		if ($azureBots) {
			$azureBots.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Bots')
			[pscustomobject]$obj = @{
				Data = $azureBots;
				Metadata = $monkey_metadata;
			}
			$returnData.az_bots = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Bots",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureBotsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










