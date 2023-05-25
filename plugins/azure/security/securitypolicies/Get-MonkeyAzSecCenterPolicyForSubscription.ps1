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


function Get-MonkeyAzSecCenterPolicyForSubscription {
<#
        .SYNOPSIS
		Plugin to get information about policies applied to subscription

        .DESCRIPTION
		Plugin to get information about policies applied to subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSecCenterPolicyForSubscription
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
			Id = "az00036";
			Provider = "Azure";
			Resource = "DefenderForCloud";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAzSecCenterPolicyForSubscription";
			ApiType = "resourceManagement";
			Title = "Plugin to get information about subscription policies";
			Group = @("DefenderForCloud");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Security Portal Auth
		$SecPortalAuth = $O365Object.auth_tokens.SecurityPortal
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Subscription Policies",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureSecPoliciesInfo');
		}
		Write-Information @msg
		#Get Subscription ID
		$subscriptionID = $O365Object.current_subscription.subscriptionId
		#Construct URI
		$URI = ("{0}Policy/getPreventionPolicy?subscriptionIdOrMgName={1}&isMg=false" -f $O365Object.Environment.Security,$subscriptionID)
		$params = @{
			Environment = $Environment;
			Authentication = $SecPortalAuth;
			OwnQuery = $URI;
			ContentType = 'application/json';
			Method = "GET";
		}
		$azure_subscription_policies = Get-MonkeyRMObject @params
	}
	end {
		if ($azure_subscription_policies -is [System.Object]) {
			$azure_subscription_policies.PSObject.TypeNames.Insert(0,'Monkey365.Azure.subscription.policies')
			[pscustomobject]$obj = @{
				Data = $azure_subscription_policies;
				Metadata = $monkey_metadata;
			}
			$returnData.az_subscription_policies = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Subscription Policies",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureKeySubscriptionPoliciesEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




