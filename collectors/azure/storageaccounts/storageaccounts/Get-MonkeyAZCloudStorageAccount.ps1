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

function Get-MonkeyAZCloudStorageAccount {
<#
        .SYNOPSIS
		Collector extract Storage Account information from Azure
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-https-stor-acct
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-store-file-enc

        .DESCRIPTION
		Collector extract Storage Account information from Azure
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-https-stor-acct
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-store-file-enc

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZCloudStorageAccount
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
			Id = "az00040";
			Provider = "Azure";
			Resource = "StorageAccounts";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZCloudStorageAccount";
			ApiType = "resourceManagement";
			description = "Collector to get information from Azure Storage account";
			Group = @(
				"StorageAccounts"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"az_storage_accounts"
			);
			dependsOn = @(

			);
		}
		#Get Config
		$strConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureStorage" } | Select-Object -ExpandProperty resource
		#Get Storage accounts
		$storage_accounts = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Storage/storageAccounts' }
		if (-not $storage_accounts) { continue }
		#Set null
		$all_str_accounts = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Storage accounts",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureStorageAccountsInfo');
		}
		Write-Information @msg
		#Check storage accounts
        if($storage_accounts.Count -gt 0){
            $new_arg = @{
				APIVersion = $strConfig.api_version;
			}
            $p = @{
			    ScriptBlock = { Get-MonkeyAzStorageAccountInfo -InputObject $_ };
                Arguments = $new_arg;
			    Runspacepool = $O365Object.monkey_runspacePool;
			    ReuseRunspacePool = $true;
			    Debug = $O365Object.VerboseOptions.Debug;
			    Verbose = $O365Object.VerboseOptions.Verbose;
			    MaxQueue = $O365Object.MaxQueue;
			    BatchSleep = $O365Object.BatchSleep;
			    BatchSize = $O365Object.BatchSize;
		    }
            $all_str_accounts = $storage_accounts | Invoke-MonkeyJob @p
        }
	}
	end {
		if ($all_str_accounts) {
			$all_str_accounts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.StorageAccounts')
			[pscustomobject]$obj = @{
				Data = $all_str_accounts;
				Metadata = $monkey_metadata;
			}
			$returnData.az_storage_accounts = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Storage accounts",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureStorageAccountsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}


