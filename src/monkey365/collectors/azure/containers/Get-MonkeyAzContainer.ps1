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



function Get-MonkeyAzContainer {
<#
        .SYNOPSIS
		Collector to get information about Azure Containers
        https://docs.microsoft.com/en-us/rest/api/container-instances/container-groups/list-by-resource-group#encryptionproperties

        .DESCRIPTION
		Collector to get information about Azure Containers
        https://docs.microsoft.com/en-us/rest/api/container-instances/container-groups/list-by-resource-group#encryptionproperties

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzContainer
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
			Id = "az00007";
			Provider = "Azure";
			Resource = "Containers";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzContainer";
			ApiType = "resourceManagement";
			description = "Collector to get information about Azure Containers";
			Group = @(
				"Containers"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_containers"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$cntAPI = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureContainers" } | Select-Object -ExpandProperty resource
		#Get container groups
		$container_groups = $O365Object.all_resources | Where-Object { $_.type -eq 'Microsoft.ContainerInstance/containerGroups' }
		if (-not $container_groups) { continue }
		$all_containers = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Containers",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureContainerInfo');
		}
		Write-Information @msg
        If ($container_groups.Count -gt 0) {
			$new_arg = @{
				APIVersion = $cntAPI.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzContainerInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$all_containers = $container_groups | Invoke-MonkeyJob @p
		}
	}
	End {
		If ($all_containers) {
			$all_containers.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Containers')
			[pscustomobject]$obj = @{
				Data = $all_containers;
				Metadata = $monkey_metadata;
			}
			$returnData.az_containers = $obj
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Containers",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureContainersEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









