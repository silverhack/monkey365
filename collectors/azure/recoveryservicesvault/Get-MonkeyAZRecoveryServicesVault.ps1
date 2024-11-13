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

function Get-MonkeyAZRecoveryServicesVault {
<#
        .SYNOPSIS
		Collector to get Recovery services Vault information from Azure

        .DESCRIPTION
		Collector to get Recovery services Vault information from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZRecoveryServicesVault
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
			Id = "az00054";
			Provider = "Azure";
			Resource = "RecoveryServicesVault";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZRecoveryServicesVault";
			ApiType = "resourceManagement";
			description = "Collector to get information from Azure Recovery Services Vault";
			Group = @(
				"RecoveryServicesVault"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_recovery_services_vault"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$vaultConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureVault" } | Select-Object -ExpandProperty resource
		#Get vaults
		$vaults = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.RecoveryServices/vaults' }
		if (-not $vaults) { continue }
		#Set null
		$all_vaults = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Recovery Services Vault",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureRecoveryServicesVaultInfo');
		}
		Write-Information @msg
		#Check storage accounts
		if ($vaults.Count -gt 0) {
			$new_arg = @{
				APIVersion = $vaultConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzRecoveryServiceVaultInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.MaxQueue;
				BatchSleep = $O365Object.BatchSleep;
				BatchSize = $O365Object.BatchSize;
			}
			$all_vaults = $vaults | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($all_vaults) {
			$all_vaults.PSObject.TypeNames.Insert(0,'Monkey365.Azure.RecoveryServicesVault')
			[pscustomobject]$obj = @{
				Data = $all_vaults;
				Metadata = $monkey_metadata;
			}
			$returnData.az_recovery_services_vault = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Recovery Services Vault",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureRecoveryServicesVaultEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}



