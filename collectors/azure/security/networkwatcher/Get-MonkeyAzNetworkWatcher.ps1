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
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"az_network_watcher",
				"az_network_watcher_flow_logs"
			);
			dependsOn = @(

			);
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Network Watcher locations
		$network_watcher_locations = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Network/networkWatchers' } | Select-Object -ExpandProperty location
		#Get Network watcher IDs
		$network_watchers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Network/networkWatchers' } | Select-Object id,location
		#Get Network Security groups
		$network_security_groups = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Network/networkSecurityGroups' -or $_.type -like 'Microsoft.ClassicNetwork/networkSecurityGroups' } | Select-Object id,location
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
		#Get All locations
		$URI = ("{0}{1}/locations?api-Version={2}" `
 				-f $O365Object.Environment.ResourceManager,$O365Object.current_subscription.Id,'2016-06-01')
		$params = @{
			Authentication = $rm_auth;
			OwnQuery = $URI;
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
		}
		$azure_locations = Get-MonkeyRMObject @params
		$locations = $azure_locations | Select-Object -ExpandProperty name
		if ($network_watcher_locations -and $locations) {
			#Compare objects
			$effective_nw_locations = Compare-Object -ReferenceObject $network_watcher_locations -DifferenceObject $locations -PassThru
			if ($effective_nw_locations) {
				$network_watcher = New-Object -TypeName PSCustomObject
				$network_watcher | Add-Member -Type NoteProperty -Name all_locations_enabled -Value $false
				$network_watcher | Add-Member -Type NoteProperty -Name locations -Value (@($effective_nw_locations) -join ',')
			}
			else {
				$network_watcher = New-Object -TypeName PSCustomObject
				$network_watcher | Add-Member -Type NoteProperty -Name all_locations_enabled -Value $true
				$network_watcher | Add-Member -Type NoteProperty -Name locations -Value (@($network_watcher_locations) -join ',')
			}
		}
		#Check if flow logs are enabled
		if ($network_watchers) {
			$all_nsg_flows = @()
			foreach ($nw in $network_watchers) {
				$region_nws = $network_security_groups | Where-Object { $_.location -eq $nw.location } | Select-Object -ExpandProperty id
				if ($region_nws) {
					foreach ($network in $region_nws) {
						#Get flow log
						$POSTDATA = @{ "TargetResourceId" = $network; } | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
						$URI = ("{0}{1}/queryFlowLogStatus?api-Version={2}" `
 								-f $O365Object.Environment.ResourceManager,$nw.Id,'2018-11-01')

						$params = @{
							Authentication = $rm_auth;
							OwnQuery = $URI;
							Environment = $Environment;
							ContentType = 'application/json';
							Method = "POST";
							Data = $POSTDATA;
						}
						$flow_log_cnf = Get-MonkeyRMObject @params
						if ($flow_log_cnf) {
							$network_flow = New-Object -TypeName PSCustomObject
							$network_flow | Add-Member -Type NoteProperty -Name target_resource_id -Value $flow_log_cnf.targetResourceId
							$network_flow | Add-Member -Type NoteProperty -Name storageId -Value $flow_log_cnf.Properties.storageId
							$network_flow | Add-Member -Type NoteProperty -Name enabled -Value $flow_log_cnf.Properties.enabled
							$network_flow | Add-Member -Type NoteProperty -Name retentionPolicyEnabled -Value $flow_log_cnf.Properties.retentionPolicy.enabled
							$network_flow | Add-Member -Type NoteProperty -Name retentionPolicyDays -Value $flow_log_cnf.Properties.retentionPolicy.Days
							$network_flow | Add-Member -Type NoteProperty -Name rawObject -Value $flow_log_cnf
							#Add to array
							$all_nsg_flows += $network_flow;
						}
					}

				}

			}
		}
	}
	end {
		if ($network_watcher) {
			$network_watcher.PSObject.TypeNames.Insert(0,'Monkey365.Azure.NetworkWatcher')
			[pscustomobject]$obj = @{
				Data = $network_watcher;
				Metadata = $monkey_metadata;
			}
			$returnData.az_network_watcher = $obj
		}
		else {
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
		#Add network flows
		if ($all_nsg_flows) {
			$all_nsg_flows.PSObject.TypeNames.Insert(0,'Monkey365.Azure.NetworkWatcher.flows_logs')
			[pscustomobject]$obj = @{
				Data = $all_nsg_flows;
				Metadata = $monkey_metadata;
			}
			$returnData.az_network_watcher_flow_logs = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Network Watcher Flow Logs",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureKeyNetworkWatcherFLEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







