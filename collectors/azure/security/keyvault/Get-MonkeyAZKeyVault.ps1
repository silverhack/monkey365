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


function Get-MonkeyAZKeyVault {
<#
        .SYNOPSIS
		Azure Collector to get all keyvaults in subscription

        .DESCRIPTION
		Azure Collector to get all keyvaults in subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZKeyVault
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","",Scope = "Function")]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "az00080";
			Provider = "Azure";
			Resource = "KeyVault";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZKeyVault";
			ApiType = "resourceManagement";
			description = "Collector to get Azure Keyvault information";
			Group = @(
				"KeyVault"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_keyvault"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$keyvault_Config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureKeyVault" } | Select-Object -ExpandProperty resource
		#Get Keyvaults
		$KeyVaults = $O365Object.all_resources.Where({ $_.type -like 'Microsoft.KeyVault/*' })
		#Set list
		$all_keyvault = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure KeyVault",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureKeyVaultInfo');
		}
		Write-Information @msg
		if ($KeyVaults.Count -gt 0) {
			$new_arg = @{
				APIVersion = $keyvault_Config.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzKeyVaultInfo -KeyVault $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$all_keyvault = $KeyVaults | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($all_keyvault) {
			$all_keyvault.PSObject.TypeNames.Insert(0,'Monkey365.Azure.KeyVault')
			[pscustomobject]$obj = @{
				Data = $all_keyvault;
				Metadata = $monkey_metadata;
			}
			$returnData.az_keyvault = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure KeyVaults",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureKeyVaultsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










