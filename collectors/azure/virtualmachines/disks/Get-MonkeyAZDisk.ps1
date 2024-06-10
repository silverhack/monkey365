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
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"az_managed_disks"
			);
			dependsOn = @(

			);
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Azure Storage Auth
		$AzureDiskConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureDisk" } | Select-Object -ExpandProperty resource
		#Get disks
		$managed_disks = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Compute/disks' }
		if (-not $managed_disks) { continue }
		#Set array
		$all_managed_disks = @();
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
		#Iterate over disks
		if ($managed_disks) {
			foreach ($disk in $managed_disks) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $disk.Name,"Disk");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureVMInfo');
				}
				Write-Information @msg
				#Construct URI
				$URI = ("{0}{1}?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,`
 						$disk.Id,$AzureDiskConfig.api_version)

				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$managed_disk = Get-MonkeyRMObject @params
				if ($managed_disk.Id) {
					$new_disk = New-Object -TypeName PSCustomObject
					$new_disk | Add-Member -Type NoteProperty -Name id -Value $managed_disk.Id
					$new_disk | Add-Member -Type NoteProperty -Name name -Value $managed_disk.Name
                    $new_disk | Add-Member -Type NoteProperty -Name type -Value $managed_disk.type
                    $new_disk | Add-Member -Type NoteProperty -Name resourceGroupName -Value $managed_disk.Id.Split("/")[4];
					$new_disk | Add-Member -Type NoteProperty -Name location -Value $managed_disk.location
					$new_disk | Add-Member -Type NoteProperty -Name skuname -Value $managed_disk.SKU.Name
					$new_disk | Add-Member -Type NoteProperty -Name skutier -Value $managed_disk.SKU.tier
					$new_disk | Add-Member -Type NoteProperty -Name ostype -Value $managed_disk.Properties.osType
					$new_disk | Add-Member -Type NoteProperty -Name disksize -Value $managed_disk.Properties.diskSizeGB
					$new_disk | Add-Member -Type NoteProperty -Name timecreated -Value $managed_disk.Properties.timeCreated
					$new_disk | Add-Member -Type NoteProperty -Name provisioningState -Value $managed_disk.Properties.provisioningState
					$new_disk | Add-Member -Type NoteProperty -Name diskState -Value $managed_disk.Properties.diskState
					$new_disk | Add-Member -Type NoteProperty -Name managedBy -Value $managed_disk.managedBy
					$new_disk | Add-Member -Type NoteProperty -Name tags -Value $managed_disk.Tags
					$new_disk | Add-Member -Type NoteProperty -Name properties -Value $managed_disk.Properties
					$new_disk | Add-Member -Type NoteProperty -Name rawObject -Value $managed_disk
					#Get OS disk Encryption status
					if ($null -ne $managed_disk.Properties.PSObject.Properties.Item('encryptionSettingsCollection')) {
						if ($managed_disk.Properties.encryptionSettingsCollection.enabled -eq $true) {
							$new_disk | Add-Member -Type NoteProperty -Name os_disk_encryption -Value "Enabled"
						}
						else {
							$new_disk | Add-Member -Type NoteProperty -Name os_disk_encryption -Value "Disabled"
						}
					}
					else {
						$new_disk | Add-Member -Type NoteProperty -Name os_disk_encryption -Value "Disabled"
					}
					#Get SSE encryption status
					$new_disk | Add-Member -Type NoteProperty -Name sse_encryption -Value $managed_disk.Properties.encryption.type
					#Add to array
					$all_managed_disks += $new_disk
				}
			}
		}
	}
	end {
		if ($all_managed_disks) {
			$all_managed_disks.PSObject.TypeNames.Insert(0,'Monkey365.Azure.managed_disks')
			[pscustomobject]$obj = @{
				Data = $all_managed_disks;
				Metadata = $monkey_metadata;
			}
			$returnData.az_managed_disks = $obj
		}
		else {
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







