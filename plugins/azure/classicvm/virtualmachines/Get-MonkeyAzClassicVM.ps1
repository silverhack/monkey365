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


function Get-MonkeyAzClassicVM {
<#
        .SYNOPSIS
		Plugin to get classic VMs from Azure

        .DESCRIPTION
		Plugin to get classic VMs from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzClassicVM
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
		#Import Localized data
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00005";
			Provider = "Azure";
			Title = "Plugin to get classic VMs from Azure";
			Group = @("VirtualMachines");
			ServiceName = "Azure Classic VM";
			PluginName = "Get-MonkeyAzClassicVM";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Classic VMs
		$classic_vms = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.ClassicCompute/virtualMachines' }
		if (-not $classic_vms) { continue }
		#Get config
		$AzureClassicVMConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureClassicVM" } | Select-Object -ExpandProperty resource
		#Set array
		$AllClassicVM = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure virtual machine",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureVMInfo');
		}
		Write-Information @msg
		if ($classic_vms) {
			foreach ($classic_vm in $classic_vms) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $classic_vm.Name,'virtual machine');
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureVMInfoMessage');
				}
				Write-Information @msg
				#Construct URI
				$URI = ("{0}{1}?api-version={2}" `
 						-f $O365Object.Environment.ResourceManager,`
 						$classic_vm.id,$AzureClassicVMConfig.api_version)
				#launch request
				$params = @{
					Authentication = $rm_auth;
					OwnQuery = $URI;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
				}
				$vm = Get-MonkeyRMObject @params
				if ($vm.id) {
					#Check for antimalware
					$av = $vm | Where-Object { $_.Properties.extensions.Extension -match "IaaSAntimalware" -and $_.Properties.storageProfile.operatingSystemDisk.operatingSystem -eq "Windows" }
					if ($av) {
						$vm | Add-Member -Type NoteProperty -Name antimalwareAgent -Value $true
					}
					else {
						$vm | Add-Member -Type NoteProperty -Name antimalwareAgent -Value $false
					}
					#Check for installed agent
					$agent = $vm | Where-Object { $_.Properties.extensions.Extension -match "MicrosoftMonitoringAgent" -or $_.resources.id -match "OmsAgentForLinux" }
					if ($agent) {
						$vm | Add-Member -Type NoteProperty -Name vmagentinstalled -Value $true
					}
					else {
						$vm | Add-Member -Type NoteProperty -Name vmagentinstalled -Value $false
					}
					#Check for diagnostic agent
					$agent = $vm | Where-Object { $_.Properties.extensions.Extension -match "IaaSDiagnostics" -or $_.resources.id -match "OmsAgentForLinux" }
					if ($agent) {
						$vm | Add-Member -Type NoteProperty -Name diagnosticagentinstalled -Value $true
					}
					else {
						$vm | Add-Member -Type NoteProperty -Name diagnosticagentinstalled -Value $false
					}
					#Add encryption settings
					$vm | Add-Member -Type NoteProperty -Name encryptionsettingsenabled -Value "notsupported"
					#Add to list
					$AllClassicVM += $vm
				}
			}
		}
	}
	end {
		if ($AllClassicVM) {
			$AllClassicVM.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ClassicVM')
			[pscustomobject]$obj = @{
				Data = $AllClassicVM;
				Metadata = $monkey_metadata;
			}
			$returnData.az_classic_vm = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure virtual machine",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureClassicVMEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
