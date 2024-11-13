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


function Get-MonkeyAzMysqlInfo {
<#
        .SYNOPSIS
		Collector to get about MySQL Databases from Azure

        .DESCRIPTION
		Collector to get about MySQL Databases from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzMysqlInfo
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
			Id = "az00009";
			Provider = "Azure";
			Resource = "Databases";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzMysqlInfo";
			ApiType = "resourceManagement";
			description = "Collector to get information about MySQL Databases from Azure";
			Group = @(
				"Databases"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_mysql_servers"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$configForMySql = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForMySQL" } | Select-Object -ExpandProperty resource
		$flexibleConfigForMySQL = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForMySQLFlexible" } | Select-Object -ExpandProperty resource
		#Get Mysql Servers
		$DatabaseServers = $O365Object.all_resources.Where({ $_.type -like 'Microsoft.DBforMySQL/servers' })
		$flexservers = $O365Object.all_resources.Where({ $_.type -like 'Microsoft.DBforMySQL/flexibleservers' })
		if (-not $DatabaseServers) { continue }
		#Set array
		$all_servers = [System.Collections.Generic.List[System.Object]]::new()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Mysql",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureMysqlInfo');
		}
		Write-Information @msg
		#Check if single servers
		if ($DatabaseServers.Count -gt 0) {
			$new_arg = @{
				APIVersion = $configForMySql.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzMySQlServer -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$myServers = $DatabaseServers | Invoke-MonkeyJob @p
			if ($myServers) {
				foreach ($mysql in $myServers) {
					[void]$all_servers.Add($mysql)
				}
			}
		}
		#Check if flexible servers
		if ($flexservers.Count -gt 0) {
			$new_arg = @{
				APIVersion = $flexibleConfigForMySQL.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzMySQlServer -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$myFlexServers = $flexservers | Invoke-MonkeyJob @p
			if ($myFlexServers) {
				foreach ($mysql in $myFlexServers) {
					[void]$all_servers.Add($mysql)
				}
			}
		}
	}
	end {
		if ($all_servers) {
			$all_servers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzureMySQLServer')
			[pscustomobject]$obj = @{
				Data = $all_servers;
				Metadata = $monkey_metadata;
			}
			$returnData.az_mysql_servers = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Mysql Server",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureMysqlEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}








