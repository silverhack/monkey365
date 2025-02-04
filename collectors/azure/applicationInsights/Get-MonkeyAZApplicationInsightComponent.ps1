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


function Get-MonkeyAZApplicationInsightComponent {
<#
        .SYNOPSIS
		Azure Collector to get application insight component

        .DESCRIPTION
		Azure Collector to get application insight component

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZApplicationInsightComponent
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	Begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "az000108";
			Provider = "Azure";
			Resource = "Subscription";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZApplicationInsightComponent";
			ApiType = "resourceManagement";
			description = "Azure Collector to get application insight component";
			Group = @(
				"Subscription"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_insight_component"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureInsightsComponent" } | Select-Object -ExpandProperty resource
		#Get instances
		$Instances = $O365Object.all_resources.Where({ $_.Id -like '*microsoft.insights/components*' })
		if (-not $Instances) { continue }
		$AllInstances = $null
	}
	Process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Insights Component",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureInsightsInfo');
		}
		Write-Information @msg
        if ($Instances.Count -gt 0) {
			$new_arg = @{
				APIVersion = $config.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzInsightComponentInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$AllInstances = $Instances | Invoke-MonkeyJob @p
		}
	}
	End {
		if ($AllInstances) {
			$AllInstances.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Application.Insights.Components')
			[pscustomobject]$obj = @{
				Data = $AllInstances;
				Metadata = $monkey_metadata;
			}
			$returnData.az_insight_component = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Insights Component",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureInsightsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}
