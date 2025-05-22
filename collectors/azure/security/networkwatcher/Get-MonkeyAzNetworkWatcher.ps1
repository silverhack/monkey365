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


function Get-MonkeyAZNetworkWatcher {
<#
        .SYNOPSIS
		Collector to get network watcher from Azure

        .DESCRIPTION
		Collector to get network watcher from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZNetworkWatcher
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
			Id = "az00106";
			Provider = "Azure";
			Resource = "NetworkWatcher";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZNetworkWatcher";
			ApiType = "resourceManagement";
			description = "Collector to get information from Azure Network Watcher";
			Group = @(
				"NetworkWatcher"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_network_watcher";
				"az_network_watcher_flow_logs"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
        #Get config
        $config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureNetworkWatcher" } | Select-Object -ExpandProperty resource
		#Get Network Watcher
		$networkWatchers = @($O365Object.all_resources).Where({ $_.type -like 'Microsoft.Network/networkWatchers' })
		#Set null
		$allNetworkWatchers = $null
        if (-not $networkWatchers) { continue }
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Network Watcher",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureNetworkWatcherInfo');
		}
		Write-Information @msg
        if ($networkWatchers.Count -gt 0) {
			$new_arg = @{
				APIVersion = $config.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzNetworkWatcherInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$allNetworkWatchers = $networkWatchers | Invoke-MonkeyJob @p
		}
	}
	End {
		If ($allNetworkWatchers) {
			$allNetworkWatchers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.NetworkWatcher')
			[pscustomobject]$obj = @{
				Data = $allNetworkWatchers;
				Metadata = $monkey_metadata;
			}
			$returnData.az_network_watcher = $obj
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Network Watcher",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureKeyNetworkWatcherEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









