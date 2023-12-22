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


function Get-MonkeyAzLogProfile {
<#
        .SYNOPSIS
		Collector to get log profile from Azure

        .DESCRIPTION
		Collector to get log profile from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzLogProfile
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
			Id = "az00071";
			Provider = "Azure";
			Resource = "LogProfile";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzLogProfile";
			ApiType = "resourceManagement";
			description = "Collector to get log profile from Azure";
			Group = @(
				"LogProfile";
				"General"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"az_log_profile"
			);
			dependsOn = @(

			);
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Config
		$azure_log_config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureLogProfile" } | Select-Object -ExpandProperty resource
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Log config",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureLogConfigInfo');
		}
		Write-Information @msg
		#Get All locations
		$p = @{
			Id = $O365Object.current_subscription.Id;
			Resource = 'locations';
			APIVersion = '2016-06-01';
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
			InformationAction = $O365Object.InformationAction;
		}
		$azure_locations = Get-MonkeyAzObjectById @p
		#Get log profile
		$params = @{
			Authentication = $rm_auth;
			Provider = $azure_log_config.Provider;
			ObjectType = 'logprofiles/default';
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			APIVersion = $azure_log_config.api_version;
		}
		$Azure_Log_Profile = Get-MonkeyRMObject @params
		if ($Azure_Log_Profile.Id) {
			#Check if storage account is using Own key
			if ($Azure_Log_Profile.Properties.storageAccountId) {
				$p = @{
					Id = $Azure_Log_Profile.Properties.storageAccountId;
					APIVersion = '2019-06-01';
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$my_straccount = Get-MonkeyAzObjectById @p
				if ($my_straccount.Properties.encryption.keyvaultproperties.keyvaulturi -and $my_straccount.Properties.encryption.keyvaultproperties.keyname) {
					$Azure_Log_Profile | Add-Member -Type NoteProperty -Name storageAccountUsingOwnKey -Value $true
					$Azure_Log_Profile | Add-Member -Type NoteProperty -Name ConfiguredStorageAccount -Value $my_straccount
				}
				else {
					$Azure_Log_Profile | Add-Member -Type NoteProperty -Name storageAccountUsingOwnKey -Value $false
					$Azure_Log_Profile | Add-Member -Type NoteProperty -Name ConfiguredStorageAccount -Value $null
				}
			}
			#Check that all regiions (Including global) are checked
			$location_result = $Azure_Log_Profile.Properties.locations.Count - $azure_locations.Count
			if ($location_result -eq 1) {
				$Azure_Log_Profile | Add-Member -Type NoteProperty -Name activityLogForAllRegions -Value $true
			}
			else {
				$Azure_Log_Profile | Add-Member -Type NoteProperty -Name activityLogForAllRegions -Value $false
			}
		}
		else {
			$Azure_Log_Profile = New-Object -TypeName PSCustomObject
			$Azure_Log_Profile | Add-Member -Type NoteProperty -Name Id -Value $null
			$Azure_Log_Profile | Add-Member -Type NoteProperty -Name name -Value "NotConfigured"
			$Azure_Log_Profile | Add-Member -Type NoteProperty -Name activityLogForAllRegions -Value $false
			$Azure_Log_Profile | Add-Member -Type NoteProperty -Name retentionPolicyEnabled -Value $false
			$Azure_Log_Profile | Add-Member -Type NoteProperty -Name retentionPolicyDays -Value 0
		}
	}
	end {
		if ($Azure_Log_Profile) {
			$Azure_Log_Profile.PSObject.TypeNames.Insert(0,'Monkey365.Azure.LogProfile')
			[pscustomobject]$obj = @{
				Data = $Azure_Log_Profile;
				Metadata = $monkey_metadata;
			}
			$returnData.az_log_profile = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Log profile",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureLogProfileEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







