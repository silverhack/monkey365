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


function Get-MonkeyEXOHostedContentFilterPolicy {
<#
        .SYNOPSIS
		Collector to get information about hosted content filter policy in Exchange Online

        .DESCRIPTION
		Collector to get information about hosted content filter policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOHostedContentFilterPolicy
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
		$hosted_content_filter = $null
		#Collector metadata
		$monkey_metadata = @{
			Id = "exo0010";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXOHostedContentFilterPolicy";
			ApiType = "ExoApi";
			description = "Collector to get information about hosted content filter policy in Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_exo_content_filter_info"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Tenant info
		$tenant_info = $O365Object.Tenant
		#Get available domains for organisation
		$org_domains = $tenant_info.Domains | Select-Object -ExpandProperty id
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Online Hosted content filter policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('ExoHostedContentInfo');
		}
		Write-Information @msg
		$hosted_content_filter = Get-HostedContentFilterInfo
		if ($null -ne $hosted_content_filter) {
			foreach ($content_filter in @($hosted_content_filter)) {
				if ($content_filter.Policy.AllowedSenderDomains.Count -gt 0) {
					$params = @{
						ReferenceObject = $org_domains;
						DifferenceObject = $content_filter.Policy.AllowedSenderDomains;
						IncludeEqual = $true;
						ExcludeDifferent = $true;
					}
					$org_whitelisted = Compare-Object @params
					#Check if own domain is already whitelisted
					if ($org_whitelisted) {
						$content_filter | Add-Member -Type NoteProperty -Name IsCompanyWhiteListed -Value $true
					}
					else {
						$content_filter | Add-Member -Type NoteProperty -Name IsCompanyWhiteListed -Value $false
					}
				}
				else {
					$content_filter | Add-Member -Type NoteProperty -Name IsCompanyWhiteListed -Value $false
				}
			}
		}
	}
	end {
		if ($null -ne $hosted_content_filter) {
			$hosted_content_filter.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.HostedContentFilterPolicy')
			[pscustomobject]$obj = @{
				Data = $hosted_content_filter;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_content_filter_info = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online Hosted content filter policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoHostedContentEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










