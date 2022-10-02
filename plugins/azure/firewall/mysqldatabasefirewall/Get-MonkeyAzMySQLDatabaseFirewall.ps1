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



function Get-MonkeyAZMysqlDatabaseFirewall {
<#
        .SYNOPSIS
		Plugin to get Firewall Rules from each MySQL Server from Azure
        https://docs.microsoft.com/en-us/rest/api/mysql/firewallrules/listbyserver

        .DESCRIPTION
		Plugin to get Firewall Rules from each MySQL Server from Azure
        https://docs.microsoft.com/en-us/rest/api/mysql/firewallrules/listbyserver

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZMysqlDatabaseFirewall
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
			Id = "az00014";
			Provider = "Azure";
			Title = "Plugin to get Azure MySQL firewall rules";
			Group = @("Firewall","Databases");
			ServiceName = "Azure MySQL firewall rules";
			PluginName = "Get-MonkeyAZMysqlDatabaseFirewall";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Config
		$AzureMySQLConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForMySQL" } | Select-Object -ExpandProperty resource
		#Get Mysql Servers
		$DatabaseServers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.DBforMySQL/servers' }
		if (-not $DatabaseServers) { continue }
		#set array
		$AllMySQLFWRules = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Mysql database firewall",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureMysqlFWsInfo');
		}
		Write-Information @msg
		if ($DatabaseServers) {
			foreach ($Server in $DatabaseServers) {
				if ($Server.Name -and $Server.id) {
					$msg = @{
						MessageData = ($message.AzureUnitResourceMessage -f $Server.Name,"MySQL firewall rules");
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureMySQLServerInfo');
					}
					Write-Information @msg

					$uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,`
 							$server.id,"firewallrules",`
 							$AzureMySQLConfig.api_version)
					#Get database info
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $uri;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$MySQLFWRules = Get-MonkeyRMObject @params
					if ($MySQLFWRules.Properties) {
						foreach ($rule in $MySQLFWRules) {
							$AzureMySQLDBFWRule = New-Object -TypeName PSCustomObject
							$AzureMySQLDBFWRule | Add-Member -Type NoteProperty -Name ServerName -Value $server.Name
							$AzureMySQLDBFWRule | Add-Member -Type NoteProperty -Name Location -Value $server.location
							$AzureMySQLDBFWRule | Add-Member -Type NoteProperty -Name ResourceGroupName -Value $server.id.Split("/")[4]
							$AzureMySQLDBFWRule | Add-Member -Type NoteProperty -Name RuleName -Value $rule.Name
							$AzureMySQLDBFWRule | Add-Member -Type NoteProperty -Name StartIpAddress -Value $rule.Properties.startIpAddress
							$AzureMySQLDBFWRule | Add-Member -Type NoteProperty -Name EndIpAddress -Value $rule.Properties.endIpAddress
							#Decorate object and add to list
							$AzureMySQLDBFWRule.PSObject.TypeNames.Insert(0,'Monkey365.Azure.MySQLDatabaseFirewall')
							$AllMySQLFWRules += $AzureMySQLDBFWRule
						}
					}
				}
			}
		}
	}
	end {
		if ($AllMySQLFWRules) {
			$AllMySQLFWRules.PSObject.TypeNames.Insert(0,'Monkey365.Azure.MySQLDatabaseFirewall')
			[pscustomobject]$obj = @{
				Data = $AllMySQLFWRules;
				Metadata = $monkey_metadata;
			}
			$returnData.az_mysql_database_fw = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure MySQL Firewall rules",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureMysqlFWEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
