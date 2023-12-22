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


function Get-MonkeyAzKubernetes {
<#
        .SYNOPSIS
		Azure Collector to get kubernetes info

        .DESCRIPTION
		Azure Collector to get kubernetes info

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzKubernetes
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "az00050";
			Provider = "Azure";
			Resource = "Kubernetes";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzKubernetes";
			ApiType = "resourceManagement";
			description = "Azure Collector to get information from Azure Kubernetes";
			Group = @(
				"Kubernetes"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"az_kubernetes"
			);
			dependsOn = @(

			);
		}
		#Get kubernetes resources
		$kubernetes = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.ContainerService/managedClusters' }
		if (-not $kubernetes) { continue }
		$all_kubernetes = $null
		#Get Config
		$Kubernetes_Config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureKubernetes" } | Select-Object -ExpandProperty resource
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Kubernetes",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureContainerInfo');
		}
		Write-Information @msg
        if($null -ne $kubernetes){
            $new_arg = @{
			    APIVersion = $Kubernetes_Config.api_version;
		    }
            $p = @{
			    ScriptBlock = { Get-MonkeyAzKubernetesInfo -InputObject $_ };
                Arguments = $new_arg;
			    Runspacepool = $O365Object.monkey_runspacePool;
			    ReuseRunspacePool = $true;
			    Debug = $O365Object.VerboseOptions.Debug;
			    Verbose = $O365Object.VerboseOptions.Verbose;
			    MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
			    BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
			    BatchSize = $O365Object.nestedRunspaces.BatchSize;
		    }
            $all_kubernetes = $kubernetes | Invoke-MonkeyJob @p
        }
	}
	end {
		if ($all_kubernetes) {
			$all_kubernetes.PSObject.TypeNames.Insert(0,'Monkey365.Azure.kubernetes')
			[pscustomobject]$obj = @{
				Data = $all_kubernetes;
				Metadata = $monkey_metadata;
			}
			$returnData.az_kubernetes = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Kubernetes",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureKubernetesEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







