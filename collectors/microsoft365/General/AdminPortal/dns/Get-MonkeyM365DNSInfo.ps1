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


function Get-MonkeyM365DNSInfo {
<#
        .SYNOPSIS
		Collector to get dns information from Microsoft admin center

        .DESCRIPTION
		Collector to get dns information from Microsoft admin center

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyM365DNSInfo
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
			Id = "m365admin002";
			Provider = "Microsoft365";
			Resource = "DNS";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyM365DNSInfo";
			ApiType = $null;
			description = "Collector to get dns information from Microsoft admin center";
			Group = @(
				"AdminPortal"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_dns_settings"
			);
			dependsOn = @(
				"M365AdminPortal"
			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Getting environment
		$Environment = $O365Object.Environment
		#Get M365 admin Authentication
		$Authentication = $O365Object.auth_tokens.M365Admin
		#set null
		$Domains = $null
		#Set new list
		$allDomains = [System.Collections.Generic.List[System.Object]]::new()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft 365. DNS records",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('M365DNSInfo');
		}
		#Get all domains
		if ($null -ne $Authentication) {
			$p = @{
				Authentication = $Authentication;
				Environment = $Environment;
				InternalPath = 'domain';
				ObjectType = 'List';
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			#call admin api
			$Domains = Get-MonkeyM365AdminObject @p
			if ($Domains) {
				foreach ($domain in $Domains) {
					$p = @{
						Authentication = $Authentication;
						Environment = $Environment;
						InternalPath = 'domain';
						ObjectType = ('WorkloadDnsRecords?zoneName={0}' -f $domain.Name);
						InformationAction = $O365Object.InformationAction;
						Verbose = $O365Object.Verbose;
						Debug = $O365Object.Debug;
					}
					$dnsInfo = Get-MonkeyM365AdminObject @p
					if ($dnsInfo) {
						#Set PsCustomObject
						$dnsObject = [ordered]@{
							domain = $domain;
							dnsInfo = $dnsInfo;
						}
						#Add to array
						[void]$allDomains.Add($dnsObject);
					}
				}
			}
		}
		else {
			$msg = @{
				MessageData = ("Unable to get dns information from Microsoft 365");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $O365Object.InformationAction;
				Tags = @('M365DNSInfoWarning');
			}
			Write-Warning @msg
		}
	}
	end {
		if ($allDomains.Count -gt 0) {
			$allDomains.PSObject.TypeNames.Insert(0,'Monkey365.M365.DNS')
			[pscustomobject]$obj = @{
				Data = $allDomains;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_dns_settings = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft 365. DNS records",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('M365DNSEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}








