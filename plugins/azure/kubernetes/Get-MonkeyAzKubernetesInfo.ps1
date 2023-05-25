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


function Get-MonkeyAzKubernetesInfo {
<#
        .SYNOPSIS
		Azure plugin to get kubernetes info

        .DESCRIPTION
		Azure plugin to get kubernetes info

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzKubernetesInfo
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
			Id = "az00019";
			Provider = "Azure";
			Resource = "Kubernetes";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAzKubernetesInfo";
			ApiType = "resourceManagement";
			Title = "Azure plugin to get information from Azure Kubernetes";
			Group = @("Kubernetes");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get kubernetes resources
		$kubernetes = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.ContainerService/managedClusters' }
		if (-not $kubernetes) { continue }
		$all_kubernetes = @();
		#Get Config
		$Kubernetes_Config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureKubernetes" } | Select-Object -ExpandProperty resource
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Kubernetes",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureContainerInfo');
		}
		Write-Information @msg
		foreach ($kuber in $kubernetes) {
			$URI = ("{0}{1}?api-version={2}" `
 					-f $O365Object.Environment.ResourceManager,$kuber.Id,`
 					$Kubernetes_Config.api_version)
			#launch request
			$params = @{
				Authentication = $rm_auth;
				OwnQuery = $URI;
				Environment = $Environment;
				ContentType = 'application/json';
				Method = "GET";
			}
			$kuber_config = Get-MonkeyRMObject @params
			if ($kuber_config) {
				#Add kubernetes to array
				$all_kubernetes += $kuber_config
			}
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




