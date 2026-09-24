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


function Get-MonkeyAZNetworkSecurityGroup {
<#
        .SYNOPSIS
		Collector to get Network Security Rules from Azure

        .DESCRIPTION
		Collector to get Network Security Rules from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZNetworkSecurityGroup
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
			Id = "az00021";
			Provider = "Azure";
			Resource = "Firewall";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZNetworkSecurityGroup";
			ApiType = "resourceManagement";
			description = "Collector to get Network Security Rules from Azure";
			Group = @(
				"Firewall";
				"NetworkSecurityGroup"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_nsg_rules"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$AzureNSGConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureNSG" } | Select-Object -ExpandProperty resource
		#Get Network Security Groups
		$all_nsgs = $O365Object.all_resources.Where({ $_.type -like '*Microsoft.Network/networkSecurityGroups*'})
		if (-not $all_nsgs) { continue }
		#Set array
		$all_nsg_rules = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Network Security Groups",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureNSGInfo');
		}
		Write-Information @msg
        If ($all_nsgs.Count -gt 0) {
			$new_arg = @{
				APIVersion = $AzureNSGConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzNetworkSecurityGroupInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$all_nsg_rules = $all_nsgs | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($all_nsg_rules) {
			$all_nsg_rules.PSObject.TypeNames.Insert(0,'Monkey365.Azure.NetworkSecurityRules')
			[pscustomobject]$obj = @{
				Data = $all_nsg_rules;
				Metadata = $monkey_metadata;
			}
			$returnData.az_nsg_rules = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Network Security Rules",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureNSGEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









