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


function Get-MonkeyAzPostgreSQLInfo {
<#
        .SYNOPSIS
		Collector to get info about PostgreSQL Databases from Azure

        .DESCRIPTION
		Collector to get info about PostgreSQL Databases from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzPostgreSQLInfo
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
			Id = "az00010";
			Provider = "Azure";
			Resource = "Databases";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzPostgreSQLInfo";
			ApiType = "resourceManagement";
			description = "Collector to get info about PostgreSQL Databases from Azure";
			Group = @(
				"Databases"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_postgresql_servers"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$configForPostgreSQL = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForPostgreSQL" } | Select-Object -ExpandProperty resource
		$flexibleConfigForPostgreSQL = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForPostgreSQLFlexible" } | Select-Object -ExpandProperty resource
		#Get PostgreSQL Servers
		$DatabaseServers = $O365Object.all_resources.Where({ $_.type -like 'Microsoft.DBforPostgreSQL/servers' })
		#Get PostgreSQL flexible Servers
		$FlexibleServers = $O365Object.all_resources.Where({ $_.type -like 'Microsoft.DBforPostgreSQL/flexibleServers' })
		if (-not $DatabaseServers -or -not $FlexibleServers) { continue }
		#Set array
		$all_servers = [System.Collections.Generic.List[System.Object]]::new()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure PostgreSQL",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzurePostgreSQLInfo');
		}
		Write-Information @msg
		#Check if single servers
		if ($DatabaseServers.Count -gt 0) {
			$new_arg = @{
				APIVersion = $configForPostgreSQL.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzPostgreSQlServer -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$psqlServers = $DatabaseServers | Invoke-MonkeyJob @p
			if ($psqlServers) {
				foreach ($psql in $psqlServers) {
					[void]$all_servers.Add($psql)
				}
			}
		}
		#Check if flexible servers
		if ($FlexibleServers.Count -gt 0) {
			$new_arg = @{
				APIVersion = $flexibleConfigForPostgreSQL.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzPostgreSQlServer -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$flexiblePsql = $FlexibleServers | Invoke-MonkeyJob @p
			if ($flexiblePsql) {
				foreach ($psql in $flexiblePsql) {
					[void]$all_servers.Add($psql)
				}
			}
		}
	}
	end {
		if ($all_servers.Count -gt 0) {
			$all_servers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AzurePostgreSQLServer')
			[pscustomobject]$obj = @{
				Data = $all_servers;
				Metadata = $monkey_metadata;
			}
			$returnData.az_postgresql_servers = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PostgreSQL Server",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePostgreSQLEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









