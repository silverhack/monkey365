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


function Get-MonkeyEXOSafeLinkPolicy {
<#
        .SYNOPSIS
		Collector to get information about safe link policy in Exchange Online

        .DESCRIPTION
		Collector to get information about safe link policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOSafeLinkPolicy
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
		$exo_safe_link_policy = $null
		#Collector metadata
		$monkey_metadata = @{
			Id = "exo0005";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXOSafeLinkPolicy";
			ApiType = "ExoApi";
            objectType = 'ExchangeSafeLinkPolicy';
            immutableProperties = @(
                'policyId',
                'ruleId'
            );
			description = "Collector to get information about safe link policy in Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_exo_safelinks_info"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Online safe link policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('ExoSafeLinkPolicyInfo');
		}
		Write-Information @msg
		$exo_safe_link_policy = Get-SafeLinksInfo
		if ($null -eq $exo_safe_link_policy) {
			$exo_safe_link_policy = @{
				isEnabled = $false
			}
		}
	}
	end {
		if ($null -ne $exo_safe_link_policy) {
			$exo_safe_link_policy.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.SafeLinkPolicy')
			[pscustomobject]$obj = @{
				Data = $exo_safe_link_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_safelinks_info = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online safe link policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoSafeLinkPolicyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









