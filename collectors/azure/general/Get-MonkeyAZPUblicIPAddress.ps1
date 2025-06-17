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


function Get-MonkeyAZPublicIPAddress {
<#
        .SYNOPSIS
		Collector to get info regarding public ip addresses from Azure

        .DESCRIPTION
		Collector to get info regarding public ip addresses from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZPublicIPAddress
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
			Id = "az00061";
			Provider = "Azure";
			Resource = "publicIPAddress";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZPUblicIPAddress";
			ApiType = "resourceManagement";
			description = "Collector to get information about public ip addresses from Azure";
			Group = @(
				"publicIPAddress"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_publicIPAddress"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$AzPUblicIpConfig = $O365Object.internal_config.ResourceManager.Where({ $_.Name -eq "azurePublicIPAddress" }) | Select-Object -ExpandProperty resource
		#Get public Ips
		$publicIPs = $O365Object.all_resources.Where({ $_.type -eq 'Microsoft.Network/publicIPAddresses' });
		#Set null
		$all_publicIPs = $null
	}
	process {
		if ($publicIPs.Count -gt 0) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Public IP addresses",$O365Object.current_subscription.displayName);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePublicIpInfo');
			}
			Write-Information @msg
			$new_arg = @{
				APIVersion = $AzPUblicIpConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyPublicIpInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$all_publicIPs = $publicIPs | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($null -ne $all_publicIPs) {
			$all_publicIPs.PSObject.TypeNames.Insert(0,'Monkey365.Azure.publicIpAddress')
			[pscustomobject]$obj = @{
				Data = $all_publicIPs;
				Metadata = $monkey_metadata;
			}
			$returnData.az_publicIPAddress = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PUblic IP addresses",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePublicIpEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}

