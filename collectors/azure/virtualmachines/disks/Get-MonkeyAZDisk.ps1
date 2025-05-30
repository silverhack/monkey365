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


function Get-MonkeyAZDisk {
<#
        .SYNOPSIS
		Azure Collector to get all managed disks in subscription

        .DESCRIPTION
		Azure Collector to get all managed disks in subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZDisk
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
			Id = "az00051";
			Provider = "Azure";
			Resource = "VirtualMachines";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZDisk";
			ApiType = "resourceManagement";
			description = "Collector to get managed disk information from Azure";
			Group = @(
				"VirtualMachines"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_managed_disks"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Azure Storage Auth
		$AzureDiskConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureDisk" } | Select-Object -ExpandProperty resource
		#Get disks
		$managed_disks = $O365Object.all_resources.Where({ $_.type -like 'Microsoft.Compute/disks' })
		if (-not $managed_disks) { continue }
		#Set array
		$all_managed_disks = $null;
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Disks",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureDiskInfo');
		}
		Write-Information @msg
		#Start new job
		If ($managed_disks) {
            $new_arg = @{
				APIVersion = $AzureDiskConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzDiskInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$all_managed_disks = $managed_disks | Invoke-MonkeyJob @p
        }
	}
	End {
		If ($all_managed_disks) {
			$all_managed_disks.PSObject.TypeNames.Insert(0,'Monkey365.Azure.managed_disks')
			[pscustomobject]$obj = @{
				Data = $all_managed_disks;
				Metadata = $monkey_metadata;
			}
			$returnData.az_managed_disks = $obj
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Disks",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureDiskEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









