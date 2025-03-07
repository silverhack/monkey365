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


function Get-MonkeyADPortalConditionalPoliciesInfo {
<#
        .SYNOPSIS
		Collector to get conditional policies from Microsoft Entra ID

        .DESCRIPTION
		Collector to get conditional policies from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADPortalConditionalPoliciesInfo
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
		$Environment = $O365Object.Environment
		#Collector metadata
		$monkey_metadata = @{
			Id = "aad0023";
			Provider = "EntraID";
			Resource = "EntraIDPortal";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyADPortalConditionalPoliciesInfo";
			ApiType = "EntraIDPortal";
			description = "Collector to get conditional policies from Microsoft Entra ID";
			Group = @(
				"EntraIDPortal"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_conditional_policies"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID conditional policies",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalCAPs');
		}
		Write-Information @msg
		#Get Policies
		$params = @{
			Authentication = $AADAuth;
			Query = 'Policies/Policies?top=100&nextLink=null&appId=&includeBaseline=true';
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$ad_conditional_policies = Get-MonkeyAzurePortalObject @params
		if ($ad_conditional_policies) {
			foreach ($policy in $ad_conditional_policies) {
				$params = @{
					Authentication = $AADAuth;
					Query = ('Policies/{0}' -f $policy.policyId);
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
					InformationAction = $O365Object.InformationAction;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
				}
				$raw_policy = Get-MonkeyAzurePortalObject @params
				if ($raw_policy) {
					$policy | Add-Member -Type NoteProperty -Name rawPolicy -Value $raw_policy -Force
				}
				else {
					$policy | Add-Member -Type NoteProperty -Name rawPolicy -Value $null -Force
				}
			}
		}
	}
	end {
		if ($ad_conditional_policies) {
			$ad_conditional_policies.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.ConditionalPolicies')
			[pscustomobject]$obj = @{
				Data = $ad_conditional_policies;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_conditional_policies = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID conditional policies",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalCAPsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










