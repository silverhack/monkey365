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

function Get-MonkeyAZAPIM {
<#
        .SYNOPSIS
		Collector to get information about Azure API Management

        .DESCRIPTION
		Collector to get information about Azure API Management

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZAPIM
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
			Id = "az00120";
			Provider = "Azure";
			Resource = "APIM";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZAPIM";
			ApiType = "resourceManagement";
			description = "Collector to get information about Azure API Management";
			Group = @(
				"APIM"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_APIM"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$APIMConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "APIManagement" } | Select-Object -ExpandProperty resource
		#Get Storage accounts
		$APIM_objects = $O365Object.all_resources.Where({ $_.type -like 'Microsoft.ApiManagement/service' })
		if (-not $APIM_objects) { continue }
		#Set array
		$all_APIM = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure API Management",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureAPIManagementInfo');
		}
		Write-Information @msg
		if ($APIM_objects.Count -gt 0) {
			$new_arg = @{
				APIVersion = $APIMConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzAPIMInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				BatchSize = $O365Object.nestedRunspaces.BatchSize;
			}
			$all_APIM = $APIM_objects | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($all_APIM) {
			$all_APIM.PSObject.TypeNames.Insert(0,'Monkey365.Azure.APIM')
			[pscustomobject]$obj = @{
				Data = $all_APIM;
				Metadata = $monkey_metadata;
			}
			$returnData.az_APIM = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure API Management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureAPIMEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}





