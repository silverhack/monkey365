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


function Get-MonkeyEXOATPPolicy {
<#
        .SYNOPSIS
		Collector to get information about ATP policy from Exchange Online

        .DESCRIPTION
		Collector to get information about ATP policy from Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOATPPolicy
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
		$atp_policy = $null;
		#Collector metadata
		$monkey_metadata = @{
			Id = "exo0004";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXOATPPolicy";
			ApiType = "ExoApi";
			description = "Collector to get information about ATP policy from Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_exo_atp_policy"
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
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Online ATP policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('ExoATPPolicyInfo');
		}
		Write-Information @msg
		If ($O365Object.Tenant.licensing.ATPEnabled) {
			#Get APT Policy
			$p = @{
				Authentication = $ExoAuth;
				Environment = $Environment;
				ResponseFormat = 'clixml';
				Command = 'Get-AtpPolicyForO365';
				Method = "POST";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			$atp_policy = Get-PSExoAdminApiObject @p
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
			#Set atpPolicy to null
			$atp_policy = $null
			break
		}
	}
	end {
		if ($atp_policy) {
			$atp_policy.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.atp_policy')
			[pscustomobject]$obj = @{
				Data = $atp_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_atp_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online ATP policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoAtpPolicyEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









