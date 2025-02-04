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


function Get-MonkeyAzSQLInfo {
<#
        .SYNOPSIS
		Collector to get information about SQL Databases from Azure

        .DESCRIPTION
		Collector to get information about SQL Databases from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSQLInfo
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
			Id = "az00011";
			Provider = "Azure";
			Resource = "Databases";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzSQLInfo";
			ApiType = "resourceManagement";
			description = "Collector to get information about SQL Databases from Azure";
			Group = @(
				"Databases"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_sql_servers"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$AzureSQLConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForSQL" } | Select-Object -ExpandProperty resource
		#Get SQL Servers
		$DatabaseServers = $O365Object.all_resources.Where({ $_.type -like 'Microsoft.Sql/servers' })
		if (-not $DatabaseServers) { continue }
		$AllServers = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure SQL",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureSQLInfo');
		}
		Write-Information @msg
		if ($DatabaseServers.Count -gt 0) {
			$new_arg = @{
				APIVersion = $AzureSQLConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzSQlServer -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$AllServers = $DatabaseServers | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($AllServers) {
			$AllServers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SQLServer')
			[pscustomobject]$obj = @{
				Data = $AllServers;
				Metadata = $monkey_metadata;
			}
			$returnData.az_sql_servers = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure SQL",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureSQLEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










