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


function Get-MonkeyAZAutoProvisioning {
<#
        .SYNOPSIS
		Azure get Auto Provisioning

        .DESCRIPTION
		Azure get Auto Provisioning

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZAutoProvisioning
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
			Id = "az00110";
			Provider = "Azure";
			Resource = "VirtualMachines";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZAutoProvisioning";
			ApiType = "resourceManagement";
			description = "Collector to get information about auto provisioning";
			Group = @(
				"VirtualMachines"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_vm_provisioning_status"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure autoprovisioning",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureAutoProvisioningInfo');
		}
		Write-Information @msg
		#List Auto provisioning status
		$params = @{
			Authentication = $rm_auth;
			Provider = "microsoft.Security";
			ObjectType = "autoProvisioningSettings";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			APIVersion = "2017-08-01-preview";
		}
		$autoProvisioningStatus = Get-MonkeyRMObject @params
		if ($autoProvisioningStatus) {
			$default_provisioning_status = $autoProvisioningStatus | Where-Object { $_.Name -eq 'default' } | Select-Object -ExpandProperty properties
			$provisioning_status = New-Object -TypeName PSCustomObject
			$provisioning_status | Add-Member -Type NoteProperty -Name Name -Value 'default'
			$provisioning_status | Add-Member -Type NoteProperty -Name autoprovision -Value $default_provisioning_status.autoProvision
			$provisioning_status | Add-Member -Type NoteProperty -Name rawObject -Value $autoProvisioningStatus
		}
	}
	end {
		if ($provisioning_status) {
			$provisioning_status.PSObject.TypeNames.Insert(0,'Monkey365.Azure.autoprovisioning.status')
			[pscustomobject]$obj = @{
				Data = $provisioning_status;
				Metadata = $monkey_metadata;
			}
			$returnData.az_vm_provisioning_status = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure autoprovisioning status",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureAutoProvisioningEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}








