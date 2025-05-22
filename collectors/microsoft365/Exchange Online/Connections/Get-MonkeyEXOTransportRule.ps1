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


function Get-MonkeyEXOTransportRule {
<#
        .SYNOPSIS
		Collector to get information about transport rules in Exchange Online

        .DESCRIPTION
		Collector to get information about transport rules in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOTransportRule
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
		$exo_transport_rules = $null
		#Collector metadata
		$monkey_metadata = @{
			Id = "exo0016";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXOTransportRule";
			ApiType = "ExoApi";
			description = "Collector to get information about transport rules in Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_exo_transport_rules"
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
		#Get instance
		$Environment = $O365Object.Environment
		#Get Exchange Online Auth token
		$ExoAuth = $O365Object.auth_tokens.ExchangeOnline
		$p = @{
			Authentication = $ExoAuth;
			Environment = $Environment;
			ResponseFormat = 'clixml';
			Command = $null;
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Online transport rules",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('ExoTransportRulesInfo');
		}
		Write-Information @msg
		$p.Command = 'Get-TransportRule'
		$exo_transport_rules = Get-PSExoAdminApiObject @p
		if ($null -ne $exo_transport_rules) {
			foreach ($transport_rule in $exo_transport_rules) {
				#Check if own domain is already whitelisted in SenderDomain
				if ($null -eq $transport_rule.SenderDomainIs) {
					#Set empty array
					$sdi = @('')
				}
				else {
					$sdi = $transport_rule.SenderDomainIs
				}
				$params = @{
					ReferenceObject = $org_domains;
					DifferenceObject = $sdi;
					IncludeEqual = $true;
					ExcludeDifferent = $true;
				}
				$org_whitelisted_InsenderDomain = Compare-Object @params
				#Check if own domain is already whitelisted in FromAddressContainsWords
				if ($null -eq $transport_rule.FromAddressContainsWords) {
					#Set empty array
					$facw = @('')
				}
				else {
					$facw = $transport_rule.FromAddressContainsWords
				}
				$params = @{
					ReferenceObject = $org_domains;
					DifferenceObject = $facw;
					IncludeEqual = $true;
					ExcludeDifferent = $true;
				}
				$org_whitelisted_InFromAddress = Compare-Object @params
				if ($org_whitelisted_InsenderDomain -or $org_whitelisted_InFromAddress) {
					$transport_rule | Add-Member -Type NoteProperty -Name IsCompanyWhiteListed -Value $true
				}
				else {
					$transport_rule | Add-Member -Type NoteProperty -Name IsCompanyWhiteListed -Value $false
				}
			}
		}
		if ($null -eq $exo_transport_rules) {
			$exo_transport_rules = @{
				isEnabled = $false
			}
		}
	}
	end {
		if ($null -ne $exo_transport_rules) {
			$exo_transport_rules.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.TransportRules')
			[pscustomobject]$obj = @{
				Data = $exo_transport_rules;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_transport_rules = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online transport rules",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoTransportRulesResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









