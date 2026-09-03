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


function Get-MonkeyAzAppServiceEnvironment {
<#
        .SYNOPSIS
		Collector to get information from Azure App Service Environment

        .DESCRIPTION
		Collector to get information from Azure App Service Environment

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAppServiceEnvironment
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
			Id = "az00163";
			Provider = "Azure";
			Resource = "App Service Environment";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzAppServiceEnvironment";
			ApiType = "resourceManagement";
			description = "Collector to get information from Azure App Service Environment";
			Group = @(
				"AppServices"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_app_service_environment"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#config
        $config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureAppServiceEnvironment" } | Select-Object -ExpandProperty resource
        #Get all app service hosting environments
        $hostingEnvironments = $O365Object.all_resources.Where({ $_.type -eq 'Microsoft.Web/hostingEnvironments' })
		if (-not $hostingEnvironments) { continue }
		#Set array
		$all_environments = [System.Collections.Generic.List[System.Object]]::new()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure app service environment",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureAPPServices');
		}
		Write-Information @msg
		if ($hostingEnvironments.Count -gt 0) {
			$new_arg = @{
				APIVersion = $config.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzAppServiceEnvironmentInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep * 2;
				BatchSize = [int][Math]::Truncate($O365Object.nestedRunspaces.BatchSize / 3);
			}
			$all_environments = $hostingEnvironments | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($all_environments) {
			$all_environments.PSObject.TypeNames.Insert(0,'Monkey365.Azure.AppService.Environment')
			[pscustomobject]$obj = @{
				Data = $all_environments;
				Metadata = $monkey_metadata;
			}
			$returnData.az_app_service_environment = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure app service Environment",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureAppServicesEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









