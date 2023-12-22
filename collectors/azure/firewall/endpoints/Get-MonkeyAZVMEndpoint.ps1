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


function Get-MonkeyAZVMEndpoint {
<#
        .SYNOPSIS
		Collector to get information regarding EndPoints from Azure

        .DESCRIPTION
		Collector to get information regarding EndPoints from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZVMEndpoint
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
			Id = "az00020";
			Provider = "Azure";
			Resource = "Firewall";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZVMEndpoint";
			ApiType = "resourceManagement";
			description = "Collector to get information about EndPoints from Azure";
			Group = @(
				"Firewall";
				"VirtualMachines"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"az_classic_endpoints"
			);
			dependsOn = @(

			);
		}
		#Get Config
		$AzureClassicVMConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureClassicVM" } | Select-Object -ExpandProperty resource
		#Get Classic VMs
		$classic_vms = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.ClassicCompute/virtualMachines' }
		if (-not $classic_vms) { continue }
		#Set Array
		$all_classic_endpoints = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure classic VMs Endpoints",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureEndpointsInfo');
		}
		Write-Information @msg
		if ($classic_vms) {
			foreach ($classic_vm in $classic_vms) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $classic_vm.Name,"classic virtual machine");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureDocumentDBServerInfo');
				}
				Write-Information @msg
				#Set query
				$p = @{
					Id = $classic_vm.Id;
					APIVersion = $AzureClassicVMConfig.api_version;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$vm = Get-MonkeyAzObjectById @p
				if ($vm.Id) {
					$endpoints = $vm.Properties.networkProfile.inputEndpoints
					foreach ($Endpoint in $Endpoints) {
						$new_classic_endpoint = New-Object -TypeName PSCustomObject
						$new_classic_endpoint | Add-Member -Type NoteProperty -Name VMName -Value $VM.Name
						$new_classic_endpoint | Add-Member -Type NoteProperty -Name EndPointName -Value $EndPoint.EndPointName
						$new_classic_endpoint | Add-Member -Type NoteProperty -Name publicIpAddress -Value $EndPoint.publicIpAddress
						$new_classic_endpoint | Add-Member -Type NoteProperty -Name privatePort -Value $EndPoint.privatePort
						$new_classic_endpoint | Add-Member -Type NoteProperty -Name publicPort -Value $EndPoint.publicPort
						$new_classic_endpoint | Add-Member -Type NoteProperty -Name protocol -Value $EndPoint.protocol
						$new_classic_endpoint | Add-Member -Type NoteProperty -Name enableDirectServerReturn -Value $EndPoint.enableDirectServerReturn
						#Add to array
						$all_classic_endpoints += $new_classic_endpoint
					}
				}
			}
		}
	}
	end {
		if ($all_classic_endpoints) {
			$all_classic_endpoints.PSObject.TypeNames.Insert(0,'Monkey365.Azure.classic.endpoints')
			[pscustomobject]$obj = @{
				Data = $all_classic_endpoints;
				Metadata = $monkey_metadata;
			}
			$returnData.az_classic_endpoints = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure classic vm endpoints",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureClassicVMEndpointEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







