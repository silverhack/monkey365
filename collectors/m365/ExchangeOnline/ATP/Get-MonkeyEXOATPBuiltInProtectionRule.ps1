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


function Get-MonkeyEXOATPBuiltInProtectionRule {
<#
        .SYNOPSIS
		Collector to get information about the rule for the Built-in protection preset security policy in Exchange Online

        .DESCRIPTION
		Collector to get information about the rule for the Built-in protection preset security policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOATPBuiltInProtectionRule
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
		$exo_policy_config = $null;
		#Collector metadata
		$monkey_metadata = @{
			Id = "exo0033";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXOATPBuiltInProtectionRule";
			ApiType = "ExoApi";
			description = "Collector to get information about the rule for the Built-in protection preset security policy in Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"o365_exo_atp_builtin_protection_rule"
			);
			dependsOn = @(

			);
		}
		#Get instance
		$Environment = $O365Object.Environment
		#Get Exchange Online Auth token
		$ExoAuth = $O365Object.auth_tokens.ExchangeOnline
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Online Built-in protection preset security policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('ExoBuiltinProtectionInfo');
		}
		Write-Information @msg
		$p = @{
			Authentication = $ExoAuth;
			Environment = $Environment;
			ResponseFormat = 'clixml';
			Command = 'Get-ATPBuiltInProtectionRule';
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$exo_builtin_protection_policy = Get-PSExoAdminApiObject @p
	}
	End {
		if ($null -ne $exo_builtin_protection_policy) {
			$exo_builtin_protection_policy.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.BuiltIn.Protection.Rule')
			[pscustomobject]$obj = @{
				Data = $exo_builtin_protection_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_atp_builtin_protection_rule = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online Built-in protection preset security policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoBuiltinProtectionEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}