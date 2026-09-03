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


function Get-MonkeyAzVPNGateway {
<#
        .SYNOPSIS
		Collector to get information about existing VPN gateways from Azure

        .DESCRIPTION
		Collector to get information about existing VPN gateways from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVPNGateway
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
			Id = "az00024";
			Provider = "Azure";
			Resource = "VirtualNetwork";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzVPNGateway";
			ApiType = "resourceManagement";
			description = "Collector to get information about existing VPN gateways from Azure";
			Group = @(
				"Network"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_vpn_gateway"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$AzureVPNGatewayConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureVPNGateway" } | Select-Object -ExpandProperty resource
		#Get VPN gateways instances
		$VPNGatewaysInstances = $O365Object.all_resources.Where({ $_.Id -like '*Microsoft.Network/virtualNetworkGateways*' })
		if (-not $VPNGatewaysInstances) { continue }
		$AllVPNGateways = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure VPN Gateway",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureVPNGatewayInfo');
		}
		Write-Information @msg
		If ($VPNGatewaysInstances.Count -gt 0) {
			$new_arg = @{
				APIVersion = $AzureVPNGatewayConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzVirtualNetworkGatewayInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
                InformationAction = $O365Object.InformationAction;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$AllVPNGateways = $VPNGatewaysInstances | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($AllVPNGateways) {
			$AllVPNGateways.PSObject.TypeNames.Insert(0,'Monkey365.Azure.VPNGateway')
			[pscustomobject]$obj = @{
				Data = $AllVPNGateways;
				Metadata = $monkey_metadata;
			}
			$returnData.az_vpn_gateway = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure VPN Gateway",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureVPNGatewayEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}