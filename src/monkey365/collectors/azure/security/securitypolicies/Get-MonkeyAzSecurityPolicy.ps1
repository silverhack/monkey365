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



function Get-MonkeyAzSecurityPolicy {
<#
        .SYNOPSIS
		Collector to get information about Security Policies from Azure
        https://msdn.microsoft.com/en-us/library/azure/mt704061.aspx

        .DESCRIPTION
		Collector to get information about Security Policies from Azure
        https://msdn.microsoft.com/en-us/library/azure/mt704061.aspx

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSecurityPolicy
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
			Id = "az00100";
			Provider = "Azure";
			Resource = "Subscription";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzSecurityPolicy";
			ApiType = "resourceManagement";
			description = "Collector to get information about Azure security policies";
			Group = @(
				"Subscription"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_security_policies"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get config
		$AzureSecPolicies = $O365Object.internal_config.ResourceManager.Where({$_.Name -eq "azureSecurityPolicies"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Security Policies",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureSecPoliciesInfo');
		}
		Write-Information @msg
		#List All Security Policies
        $policiesId = ("{0}/providers/{1}/policies" -f $O365Object.current_subscription.id, $AzureSecPolicies.provider)
        $p = @{
			Id = $policiesId;
            ApiVersion = $AzureSecPolicies.api_version;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
		}
		$policies = Get-MonkeyAzObjectById @p
        If($null -ne $policies){
            $policies.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Policies')
			[pscustomobject]$obj = @{
				Data = $policies;
				Metadata = $monkey_metadata;
			}
			$returnData.az_security_policies = $obj
        }
        Else{
            $msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Security Policies",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureSubscriptionPoliciesEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
        }
	}
}
