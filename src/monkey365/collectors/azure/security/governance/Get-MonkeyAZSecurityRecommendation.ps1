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


function Get-MonkeyAZAdvisorSecurityRecommendation {
<#
        .SYNOPSIS
		Collector to get cached security recommendations from Azure Advisor

        .DESCRIPTION
		Collector to get cached security recommendations from Azure Advisor

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZAdvisorSecurityRecommendation
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
			Id = "az000109";
			Provider = "Azure";
			Resource = "Subscription";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZAdvisorSecurityRecommendation";
			ApiType = "resourceManagement";
			description = "Collector to get cached security recommendations from Azure Advisor";
			Group = @(
				"Subscription"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_advisor_recommendations"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	Process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Advisor Security recommendations",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureAdvisorInfo');
		}
		Write-Information @msg
        #Get Config
		$AzureAdvisorConfig = $O365Object.internal_config.ResourceManager.Where({$_.Name -eq "azureRecommendations"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
		#Get security recommendations
		$p = @{
			Id = $O365Object.current_subscription.Id;
			Resource = 'providers/Microsoft.Advisor/recommendations';
			APIVersion = $AzureAdvisorConfig.api_version;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
			InformationAction = $O365Object.InformationAction;
		}
		$azure_recommendations = Get-MonkeyAzObjectById @p
        If($null -ne $azure_recommendations){
            $azure_recommendations.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Advisor.Recommendations')
			[pscustomobject]$obj = @{
				Data = $azure_recommendations;
				Metadata = $monkey_metadata;
			}
			$returnData.az_advisor_recommendations = $obj
        }
        Else{
            $msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Advisor Security Recommendations",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureAdvisorEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
        }
	}
}
