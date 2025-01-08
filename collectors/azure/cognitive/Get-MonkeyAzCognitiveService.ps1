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



function Get-MonkeyAzCognitiveService {
<#
        .SYNOPSIS
		Azure Cognitive Service
        https://docs.microsoft.com/en-us/rest/api/cognitiveservices/

        .DESCRIPTION
		Azure Cognitive Service
        https://docs.microsoft.com/en-us/rest/api/cognitiveservices/

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzCognitiveService
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
			Id = "az00006";
			Provider = "Azure";
			Resource = "CognitiveServices";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzCognitiveService";
			ApiType = "resourceManagement";
			description = "Azure Cognitive Service";
			Group = @(
				"CognitiveServices"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_cognitive_accounts"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$CognitiveAPI = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureCognitive" } | Select-Object -ExpandProperty resource
		#Get Cognitive Services accounts
		$cognitive_services = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.CognitiveServices/accounts' }
		if (-not $cognitive_services) { continue }
		$all_cognitive_services = @();
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Cognitive Services",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureCognitiveInfo');
		}
		Write-Information @msg
		#Get All Cognitive accounts
		if ($cognitive_services) {
			foreach ($cognitive_service in $cognitive_services) {
				#Set query
				$p = @{
					Id = $cognitive_service.Id;
					APIVersion = $CognitiveAPI.api_version;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$my_cognitive_account = Get-MonkeyAzObjectById @p
				if ($my_cognitive_account) {
					#Get Network properties
					if (-not $my_cognitive_account.Properties.NetworkRuleSet) {
						$my_cognitive_account | Add-Member -Type NoteProperty -Name allowAccessFromAllNetworks -Value $true
					}
					else {
						$my_cognitive_account | Add-Member -Type NoteProperty -Name allowAccessFromAllNetworks -Value $false
					}
					#Add cognitive account to array
					$all_cognitive_services += $my_cognitive_account
				}
			}
		}
	}
	end {
		if ($all_cognitive_services) {
			$all_cognitive_services.PSObject.TypeNames.Insert(0,'Monkey365.Azure.CognitiveAccounts')
			[pscustomobject]$obj = @{
				Data = $all_cognitive_services;
				Metadata = $monkey_metadata;
			}
			$returnData.az_cognitive_accounts = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Cognitive Services",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureCognitiveEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









