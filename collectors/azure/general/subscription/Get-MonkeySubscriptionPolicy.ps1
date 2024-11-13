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


function Get-MonkeySubscriptionPolicy {
<#
        .SYNOPSIS
		Collector to get subscription policies in Azure

        .DESCRIPTION
		Collector to get subscription policies in Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySubscriptionPolicy
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
			Id = "az00043";
			Provider = "Azure";
			Resource = "SubscriptionPolicy";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeySubscriptionPolicy";
			ApiType = "resourceManagement";
			description = "Collector to get subscription policies in Azure";
			Group = @(
				"Subscription";
				"General"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_subscription_policies"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"subscription policies",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureSubscriptionPolicyInfo');
		}
		Write-Information @msg
		#Get subscription Policies
		$p = @{
			InformationAction = $InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$subscriptionPolicies = Get-MonkeyAzSubscriptionPolicy @p
	}
	end {
		if ($subscriptionPolicies) {
			$subscriptionPolicies.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SubscriptionPolicies')
			[pscustomobject]$obj = @{
				Data = $subscriptionPolicies;
				Metadata = $monkey_metadata;
			}
			$returnData.az_subscription_policies = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "subscription policies",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureSubscriptionPolicyEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}








