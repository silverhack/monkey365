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


function Get-MonkeyAZFirewall {
<#
        .SYNOPSIS
		Collector to get info regarding firewall from Azure

        .DESCRIPTION
		Collector to get info regarding firewall from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZFirewall
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
			Id = "az00062";
			Provider = "Azure";
			Resource = "Firewall";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZFirewall";
			ApiType = "resourceManagement";
			description = "Collector to get information from Azure Firewall";
			Group = @(
				"Firewall"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_firewall"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$AzureFirewallConfig = $O365Object.internal_config.ResourceManager.Where({ $_.Name -eq "azureFirewall" }) | Select-Object -ExpandProperty resource
		#Get firewalls
		$firewalls = $O365Object.all_resources.Where({ $_.type -eq 'Microsoft.Network/azureFirewalls' });
		#Set null
		$all_firewalls = $null
	}
	process {
		if ($app_gateways.Count -gt 0) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Firewall",$O365Object.current_subscription.displayName);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureFirewallInfo');
			}
			Write-Information @msg
			$new_arg = @{
				APIVersion = $AzureFirewallConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzFirewallInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$all_firewalls = $firewalls | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($null -ne $all_firewalls) {
			$all_firewalls.PSObject.TypeNames.Insert(0,'Monkey365.Azure.firewall')
			[pscustomobject]$obj = @{
				Data = $all_firewalls;
				Metadata = $monkey_metadata;
			}
			$returnData.az_firewall = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure firewall",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureFirewallEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}
