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


function Get-MonkeyAzDataBricksAccessConnector {
<#
        .SYNOPSIS
		Azure Collector to get DataBricks access connector info

        .DESCRIPTION
		Azure Collector to get DataBricks access connector info

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzDataBricksAccessConnector
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
			Id = "az00140";
			Provider = "Azure";
			Resource = "DataBricks";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzDataBricksAccessConnector";
			ApiType = "resourceManagement";
			description = "Azure Collector to get information from Azure DataBricks access connectors";
			Group = @(
				"DataBricks"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_databricks_connector"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get access connectors resources
		$accessConnectors = $O365Object.all_resources.Where({ $_.type -like '*Microsoft.Databricks/accessConnectors*'});
		if (-not $accessConnectors) { continue }
		$allAccessConnectors = $null
		#Get Config
		$config = $O365Object.internal_config.ResourceManager.Where({ $_.Name -eq "azureDataBricksAccessConnector" }) | Select-Object -ExpandProperty resource
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure DataBricks access connectors",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureDataBricksInfo');
		}
		Write-Information @msg
		if ($accessConnectors.Count -gt 0) {
			$new_arg = @{
				APIVersion = $config.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyDataBrickAccessConnectorInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$allAccessConnectors = $accessConnectors | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($allAccessConnectors) {
			$allAccessConnectors.PSObject.TypeNames.Insert(0,'Monkey365.Azure.DataBricks.AccessConnectors')
			[pscustomobject]$obj = @{
				Data = $allAccessConnectors;
				Metadata = $monkey_metadata;
			}
			$returnData.az_databricks_connector = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure DataBricks access connectors",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureDataBricksEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}
