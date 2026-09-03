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


function Get-MonkeyAzResourceMetadata {
<#
        .SYNOPSIS
		Collector to get information about resources within a subscription

        .DESCRIPTION
		Collector to get information about resources within a subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzResourceMetadata
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns","",Scope = "Function")]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	Begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "az00165";
			Provider = "Azure";
			Resource = "Subscription";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzResourceMetadata";
			ApiType = "resourceManagement";
			description = "Collector to get information about resources within a subscription";
			Group = @(
				"Subscription"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_all_resources"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	Process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Resources",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureResourcesInfo');
		}
		Write-Information @msg
        #return object
        If ($O365Object.all_resources) {
            $allResources = $O365Object.all_resources;
			$allResources.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Resources')
			[pscustomobject]$obj = @{
				Data = $allResources;
				Metadata = $monkey_metadata;
			}
			$returnData.az_all_resources = $obj;
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Resources",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureSubscriptionEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}