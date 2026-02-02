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


function Get-MonkeyEXOPhishFilterPolicy {
<#
        .SYNOPSIS
		Collector to get information about Phish filter policy in Exchange Online

        .DESCRIPTION
		Collector to get information about Phish filter policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOPhishFilterPolicy
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
		$exo_phish_filter_policy = $null
		#Collector metadata
		$monkey_metadata = @{
			Id = "exo0003";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXOPhishFilterPolicy";
			ApiType = "ExoApi";
            objectType = 'ExchangeAntiPhishFilterPolicy';
            immutableProperties = @(
                'SpoofedSender',
                'TrueSender'
            );
			description = "Collector to get information about Phish filter policy in Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_exo_phish_filter_policy"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get instance
		$Environment = $O365Object.Environment
		#Get Exchange Online Auth token
		$ExoAuth = $O365Object.auth_tokens.ExchangeOnline
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Phish filter policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('ExoPhishFilterPolicyInfo');
		}
		Write-Information @msg
		#https://docs.microsoft.com/en-us/powershell/module/exchange/get-phishfilterpolicy?view=exchange-ps
		# TODO This cmdlet is in the process of being deprecated
		$p = @{
			Authentication = $ExoAuth;
			Environment = $Environment;
			ResponseFormat = 'clixml';
			Command = 'Get-SpoofMailReport';
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$exo_phish_filter_policy = Get-PSExoAdminApiObject @p
	}
	end {
		if ($null -ne $exo_phish_filter_policy) {
			$exo_phish_filter_policy.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.PhishFilterPolicy')
			[pscustomobject]$obj = @{
				Data = $exo_phish_filter_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_phish_filter_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Phish filter policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoPhishFilterResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









