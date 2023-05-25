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
		Plugin to get info about PostgreSQL Databases from Azure

        .DESCRIPTION
		Plugin to get info about PostgreSQL Databases from Azure

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
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00010";
			Provider = "Azure";
			Resource = "Databases";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAzPostgreSQLInfo";
			ApiType = "resourceManagement";
			Title = "Plugin to get info about PostgreSQL Databases from Azure";
			Group = @("Databases");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Config
		$configForPostgreSQL = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForPostgreSQL" } | Select-Object -ExpandProperty resource
        $flexibleConfigForPostgreSQL = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForPostgreSQLFlexible" } | Select-Object -ExpandProperty resource
		#Get PostgreSQL Servers
		$DatabaseServers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.DBforPostgreSQL/servers' }
        #Get PostgreSQL flexible Servers
		$FlexibleServers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.DBforPostgreSQL/flexibleServers' }
		if (-not $DatabaseServers -or -not $FlexibleServers) { continue }
		#Set array
		$all_servers = New-Object System.Collections.Generic.List[System.Object]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure PostgreSQL",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzurePostgreSQLInfo');
		}
		Write-Information @msg
		#Check if single servers
        if ($DatabaseServers) {
            $psql_servers = $DatabaseServers | Get-MonkeyAzPostgreSQlServer -APIVersion $configForPostgreSQL.api_version
            if($psql_servers){
                [void]$all_servers.Add($psql_servers)
            }
		}
        #Check if flexible servers
        if ($FlexibleServers) {
            $psql_servers = $FlexibleServers | Get-MonkeyAzPostgreSQlServer -APIVersion $flexibleConfigForPostgreSQL.api_version
            if($psql_servers){
                [void]$all_servers.Add($psql_servers)
            }
		}
	}
	end {
		if ($all_servers) {
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




