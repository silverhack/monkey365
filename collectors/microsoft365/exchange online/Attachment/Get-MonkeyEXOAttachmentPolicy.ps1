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


function Get-MonkeyEXOAttachmentPolicy {
<#
        .SYNOPSIS
		Collector to get information about safe attachment policy in Exchange Online

        .DESCRIPTION
		Collector to get information about safe attachment policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOAttachmentPolicy
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
		$attachment_policy = $null
		#Collector metadata
		$monkey_metadata = @{
			Id = "exo0006";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXOAttachmentPolicy";
			ApiType = "ExoApi";
            objectType = 'ExchangeSafeAttachmentPolicy';
            immutableProperties = @(
                'policyId',
                'ruleId'
            );
			description = "Collector to get information about safe attachment policy in Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_exo_safe_attachment_info"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Online safe attachment policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('ExoSafeAttachmentPolicyInfo');
		}
		Write-Information @msg
		if ($O365Object.Tenant.licensing.ATPEnabled) {
			#Enumerate Safe attachment Policy
			$attachment_policy = Get-SafeAttachmentInfo
			if ($null -eq $attachment_policy) {
				$attachment_policy = @{
					isEnabled = $false
				}
			}
		}
		else {
			$msg = @{
				MessageData = ($message.O365ATPNotDetected -f $O365Object.Tenant.CompanyInfo.displayName);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('ExoATPPolicyWarning');
			}
			Write-Information @msg
			#Set to null
			$attachment_policy = $null;
			break
		}
	}
	end {
		if ($attachment_policy) {
			$attachment_policy.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.AttachmentPolicy')
			[pscustomobject]$obj = @{
				Data = $attachment_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_safe_attachment_info = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online safe attachment policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoSafeAttachmentPolicyEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









