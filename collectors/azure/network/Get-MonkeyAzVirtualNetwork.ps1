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


function Get-MonkeyAzVirtualNetwork {
<#
        .SYNOPSIS
		Collector to get information about existing Virtual Networks from Azure

        .DESCRIPTION
		Collector to get information about existing Virtual Networks from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVPNConnection
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns","",Scope = "Function")]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "az00023";
			Provider = "Azure";
			Resource = "VirtualNetwork";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzVPNConnection";
			ApiType = "resourceManagement";
			description = "Collector to get information about existing Virtual Networks from Azure";
			Group = @(
				"Network"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_virtual_network"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$AzureVNetworkConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureVirtualNetwork" } | Select-Object -ExpandProperty resource
		#Get virtual network instances
		$VNetworkInstances = $O365Object.all_resources.Where({ $_.Id -like '*Microsoft.Network/virtualNetworks*' })
		if (-not $VNetworkInstances) { continue }
		$AllVNetworks = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Virtual Network",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureVNetworkInfo');
		}
		Write-Information @msg
		If ($VNetworkInstances.Count -gt 0) {
			$new_arg = @{
				APIVersion = $AzureVNetworkConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzVirtualNetworkInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$AllVNetworks = $VNetworkInstances | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($AllVNetworks) {
			$AllVNetworks.PSObject.TypeNames.Insert(0,'Monkey365.Azure.VirtualNetworks')
			[pscustomobject]$obj = @{
				Data = $AllVNetworks;
				Metadata = $monkey_metadata;
			}
			$returnData.az_virtual_network = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Virtual Network",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureVNetworkEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}