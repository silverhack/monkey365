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


function Get-MonkeyAZRMVM {
<#
        .SYNOPSIS
		Plugin to get information related from Resource Manager VM from Azure

        .DESCRIPTION
		Plugin to get information related from Resource Manager VM from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZRMVM
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
			Id = "az00042";
			Provider = "Azure";
			Resource = "VirtualMachines";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAZRMVM";
			ApiType = "resourceManagement";
			Title = "Plugin to get information about Azure VM";
			Group = @("VirtualMachines");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Config
		$AzureVMConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureVm" } | Select-Object -ExpandProperty resource
		#Get Azure Storage Auth
		$AzureDiskConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureDisk" } | Select-Object -ExpandProperty resource
		#Get VMs
		$vms_v2 = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Compute/virtualMachines' }
		if (-not $vms_v2) { continue }
		#set array
		$vms = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Virtual machines",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureVMInfo');
		}
		Write-Information @msg
		if ($vms_v2) {
			foreach ($rmvm in $vms_v2) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $rmvm.Name,"Virtual machine");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureVMInfo');
				}
				Write-Information @msg
				#Construct URI
				$URI = ('{0}{1}?api-version={2}&$expand=instanceView' `
 						-f $O365Object.Environment.ResourceManager,`
 						$rmvm.Id,$AzureVMConfig.api_version)
				#launch request
				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$vm = Get-MonkeyRMObject @params
				if ($vm.Id) {
					#Check for antimalware
					$av = $vm | Where-Object { $_.resources.Id -match "IaaSAntimalware" -and $_.Properties.storageProfile.osDisk.osType -eq "Windows" }
					if ($av) {
						$vm | Add-Member -Type NoteProperty -Name antimalwareAgent -Value $true
					}
					else {
						$vm | Add-Member -Type NoteProperty -Name antimalwareAgent -Value $false
					}
					#Check for installed agent
					$agent = $vm | Where-Object { $_.resources.Id -match "MicrosoftMonitoringAgent" -or $_.resources.Id -match "OmsAgentForLinux" }
					if ($agent) {
						$vm | Add-Member -Type NoteProperty -Name vmagentinstalled -Value $true
					}
					else {
						$vm | Add-Member -Type NoteProperty -Name vmagentinstalled -Value $false
					}
					#Get OS disk encryption
					$osDiskName = $vm.Properties.storageProfile.osDisk.Name
					if ($osDiskName) {
						$diskEncryption = $vm.Properties.instanceView.disks | Where-Object { $_.Name -eq $osDiskName } | Select-Object -ExpandProperty encryptionSettings -ErrorAction Ignore
						if ($null -ne $diskEncryption) {
							if ($diskEncryption.Enabled -eq $true) {
								$vm | Add-Member -Type NoteProperty -Name os_disk_encryption -Value "Enabled"
							}
							else {
								$vm | Add-Member -Type NoteProperty -Name os_disk_encryption -Value "Disabled"
							}
						}
						else {
							$vm | Add-Member -Type NoteProperty -Name os_disk_encryption -Value "Disabled"
						}
					}
					#Check if OS is a managed disk
					$osDisk = $vm.Properties.storageProfile.osDisk
					if ($null -ne $osDisk) {
						if ($null -ne $osDisk.PSObject.Properties.Item('managedDisk')) {
							$vm | Add-Member -Type NoteProperty -Name os_managed_disk -Value $true
							#Get os disk info
							$URI = ("{0}{1}?api-version={2}" `
 									-f $O365Object.Environment.ResourceManager,`
 									$osDisk.managedDisk.Id,$AzureDiskConfig.api_version)

							$params = @{
								Authentication = $rm_auth;
								OwnQuery = $URI;
								Environment = $Environment;
								ContentType = 'application/json';
								Method = "GET";
							}
							$managed_disk = Get-MonkeyRMObject @params
							if ($null -ne $managed_disk) {
								#Get SSE encryption status
								$vm | Add-Member -Type NoteProperty -Name os_sse_encryption -Value $managed_disk.Properties.encryption.type
								#Check if key is auto-rotate
								if ($null -ne $managed_disk.Properties.encryption.PSObject.Properties.Item('diskEncryptionSetId')) {
									#Get SSE Encryption Set
									$URI = ("{0}{1}?api-version={2}" `
 											-f $O365Object.Environment.ResourceManager,`
 											$managed_disk.Properties.encryption.diskEncryptionSetId,$AzureDiskConfig.api_version)

									$params = @{
										Authentication = $rm_auth;
										OwnQuery = $URI;
										Environment = $Environment;
										ContentType = 'application/json';
										Method = "GET";
									}
									$SSE_Encryption_Set = Get-MonkeyRMObject @params
									if ($null -ne $SSE_Encryption_Set) {
										$vm | Add-Member -Type NoteProperty -Name os_sse_encryption_set -Value $SSE_Encryption_Set
									}
								}
								else {
									$vm | Add-Member -Type NoteProperty -Name os_sse_encryption_set -Value $null
								}
							}
						}
						else {
							$vm | Add-Member -Type NoteProperty -Name os_managed_disk -Value $false
							#Set OS SSE encryption status to null
							$vm | Add-Member -Type NoteProperty -Name os_sse_encryption -Value $null
							$vm | Add-Member -Type NoteProperty -Name os_sse_encryption_set -Value $null
						}
					}
					$dataDisks = $vm.Properties.storageProfile.dataDisks
					if ($null -ne $dataDisks) {
						#Create array
						$all_data_disks = @()
						#Count Data Disks
						$vm | Add-Member -Type NoteProperty -Name os_data_disk_number -Value $dataDisks.Count
						foreach ($data_disk in $dataDisks) {
							$dd_name = $data_disk.Name
							if ($null -ne $dd_name) {
								#Create new PsObject
								$data_disks_info = New-Object -TypeName PSCustomObject
								$data_disks_info | Add-Member -Type NoteProperty -Name name -Value $dd_name
								$diskEncryption = $vm.Properties.instanceView.disks | Where-Object { $_.Name -eq $dd_name } | Select-Object -ExpandProperty encryptionSettings -ErrorAction Ignore
								if ($null -ne $diskEncryption) {
									if ($diskEncryption.Enabled -eq $true) {
										$data_disks_info | Add-Member -Type NoteProperty -Name disk_encryption -Value "Enabled"
									}
									else {
										$data_disks_info | Add-Member -Type NoteProperty -Name disk_encryption -Value "Disabled"
									}
								}
								else {
									$data_disks_info | Add-Member -Type NoteProperty -Name disk_encryption -Value "Disabled"
								}
								#Check if data disks are managed disks
								if ($null -ne $data_disk.PSObject.Properties.Item('managedDisk')) {
									$data_disks_info | Add-Member -Type NoteProperty -Name is_managed_disk -Value $true
									#Get managed disk info
									$URI = ("{0}{1}?api-version={2}" `
 											-f $O365Object.Environment.ResourceManager,`
 											$data_disk.managedDisk.Id,$AzureDiskConfig.api_version)

									$params = @{
										Authentication = $rm_auth;
										OwnQuery = $URI;
										Environment = $Environment;
										ContentType = 'application/json';
										Method = "GET";
									}
									$managed_disk = Get-MonkeyRMObject @params
									if ($null -ne $managed_disk) {
										#Get SSE encryption status
										$data_disks_info | Add-Member -Type NoteProperty -Name sse_encryption -Value $managed_disk.Properties.encryption.type
										#Check if key is auto-rotate
										if ($null -ne $managed_disk.Properties.encryption.PSObject.Properties.Item('diskEncryptionSetId')) {
											#Get SSE Encryption Set
											$URI = ("{0}{1}?api-version={2}" `
 													-f $O365Object.Environment.ResourceManager,`
 													$managed_disk.Properties.encryption.diskEncryptionSetId,$AzureDiskConfig.api_version)

											$params = @{
												Authentication = $rm_auth;
												OwnQuery = $URI;
												Environment = $Environment;
												ContentType = 'application/json';
												Method = "GET";
											}
											$SSE_Encryption_Set = Get-MonkeyRMObject @params
											if ($null -ne $SSE_Encryption_Set) {
												$data_disks_info | Add-Member -Type NoteProperty -Name sse_encryption_set -Value $SSE_Encryption_Set
											}
										}
										else {
											$data_disks_info | Add-Member -Type NoteProperty -Name sse_encryption_set -Value $null
										}
									}
								}
								else {
									$data_disks_info | Add-Member -Type NoteProperty -Name is_managed_disk -Value $false
									#Set SSE encryption to null
									$data_disks_info | Add-Member -Type NoteProperty -Name sse_encryption -Value $null
									$data_disks_info | Add-Member -Type NoteProperty -Name sse_encryption_set -Value $null
								}
							}
							#Add to array
							$all_data_disks += $data_disks_info
						}
					}
					#Set Data disk encryption
					$vm | Add-Member -Type NoteProperty -Name data_disks -Value $all_data_disks
					#Get network interfaces
					$NetworkInterface = $vm.Properties.networkProfile.networkinterfaces.Id
					if ($NetworkInterface) {
						$URI = ('{0}{1}?api-version={2}' -f $O365Object.Environment.ResourceManager,$NetworkInterface,'2016-03-30')
						#Perform Query
						$params = @{
							Authentication = $rm_auth;
							OwnQuery = $URI;
							Environment = $Environment;
							ContentType = 'application/json';
							Method = "GET";
						}
						$Result = Get-MonkeyRMObject @params
						if ($Result.Name) {
							$vm | Add-Member -Type NoteProperty -Name InterfaceName -Value $Result.Name
							$vm | Add-Member -Type NoteProperty -Name LocalIPAddress -Value $Result.Properties.ipConfigurations.Properties.privateIPAddress
							$vm | Add-Member -Type NoteProperty -Name MACAddress -Value $Result.Properties.macAddress
							$vm | Add-Member -Type NoteProperty -Name IPForwardingEnabled -Value $Result.Properties.enableIPForwarding
							$PublicIPEndPoint = $Result.Properties.ipConfigurations.Properties.publicIpAddress.Id
							if ($PublicIPEndPoint) {
								$URI = ('{0}{1}?api-version={2}' -f $O365Object.Environment.ResourceManager,$PublicIPEndPoint,'2016-12-01')
								$params = @{
									Authentication = $rm_auth;
									OwnQuery = $URI;
									Environment = $Environment;
									ContentType = 'application/json';
									Method = "GET";
								}
								$PublicIP = Get-MonkeyRMObject @params
								if ($PublicIP.Properties) {
									$vm | Add-Member -Type NoteProperty -Name PublicIPAddress -Value $PublicIP.Properties.ipAddress
									$vm | Add-Member -Type NoteProperty -Name publicIPAllocationMethod -Value $PublicIP.Properties.publicIPAllocationMethod
								}
							}
						}
					}
					#Add to object
					$vms += $vm
				}
			}
		}
	}
	end {
		if ($vms) {
			$vms.PSObject.TypeNames.Insert(0,'Monkey365.Azure.VirtualMachines')
			[pscustomobject]$obj = @{
				Data = $vms;
				Metadata = $monkey_metadata;
			}
			$returnData.az_virtual_machines = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Virtual machines",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureVMEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




