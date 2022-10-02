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


function Get-MonkeyAZSQLDatabaseFirewall {
<#
        .SYNOPSIS
		Plugin to get Firewall Rules from each SQL Server from Azure

        .DESCRIPTION
		Plugin to get Firewall Rules from each SQL Server from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZSQLDatabaseFirewall
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
			Id = "az00017";
			Provider = "Azure";
			Title = "Plugin to get Azure SQL firewall rules";
			Group = @("Firewall","Databases");
			ServiceName = "Azure SQL firewall rules";
			PluginName = "Get-MonkeyAZSQLDatabaseFirewall";
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
		$AzureSQLConfigFW = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForSQLFW" } | Select-Object -ExpandProperty resource
		#Get Mysql Servers
		$DatabaseServers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Sql/servers' }
		if (-not $DatabaseServers) { continue }
		#Set array
		$AllFWRules = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure SQL Database firewall",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureSQLFWInfo');
		}
		Write-Information @msg
		if ($DatabaseServers) {
			foreach ($Server in $DatabaseServers) {
				if ($Server.Name -and $Server.id) {
					$msg = @{
						MessageData = ($message.AzureUnitResourceMessage -f $Server.Name,"SQL Firewall rules");
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureSQLFWInfo');
					}
					Write-Information @msg
					$uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,`
 							$server.id,`
 							"firewallrules",`
 							$AzureSQLConfigFW.api_version)
					#Get database info
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $uri;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$FWRules = Get-MonkeyRMObject @params
					if ($FWRules.Properties) {
						foreach ($rule in $FWRules) {
							$AzureDBFWRule = New-Object -TypeName PSCustomObject
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name ServerName -Value $server.Name
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name Location -Value $server.location
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name ResourceGroupName -Value $server.id.Split("/")[4]
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name RuleLocation -Value $rule.location
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name Kind -Value $rule.kind
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name RuleName -Value $rule.Name
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name StartIpAddress -Value $rule.Properties.startIpAddress
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name EndIpAddress -Value $rule.Properties.endIpAddress
							$AzureDBFWRule | Add-Member -Type NoteProperty -Name rawObject -Value $rule
							#Decorate object and add to list
							$AzureDBFWRule.PSObject.TypeNames.Insert(0,'Monkey365.Azure.DatabaseFirewall')
							$AllFWRules += $AzureDBFWRule
						}
					}
				}
			}
		}
	}
	end {
		if ($AllFWRules) {
			$AllFWRules.PSObject.TypeNames.Insert(0,'Monkey365.Azure.DatabaseFirewall')
			[pscustomobject]$obj = @{
				Data = $AllFWRules;
				Metadata = $monkey_metadata;
			}
			$returnData.az_sql_database_fw = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure SQL firewall rules",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureSQLFWEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
