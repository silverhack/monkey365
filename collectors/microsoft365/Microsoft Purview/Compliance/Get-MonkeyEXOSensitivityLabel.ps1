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


function Get-MonkeyEXOSensitivityLabel {
<#
        .SYNOPSIS
		Collector to get information about sensitivity labels from Exchange Online

        .DESCRIPTION
		Collector to get information about sensitivity labels from Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOSensitivityLabel
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
		$sensitivity_labels = $null
		#Collector metadata
		$monkey_metadata = @{
			Id = "purv008";
			Provider = "Microsoft365";
			Resource = "Purview";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXOSensitivityLabel";
			ApiType = $null;
			description = "Collector to get information about sensitivity labels from Exchange Online";
			Group = @(
				"Purview"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_secomp_sensitivity_labels"
			);
			dependsOn = @(
				"ExchangeOnline"
			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	process {
		if ($O365Object.onlineServices.Purview -eq $true) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Security and Compliance sensitivity labels",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('SecCompLabelsInfo');
			}
			Write-Information @msg
			#Get Security and Compliance Auth token
			$ExoAuth = $O365Object.auth_tokens.ComplianceCenter
			#Get Backend Uri
			$Uri = $O365Object.SecCompBackendUri
			#InitParams
			$p = @{
				Authentication = $ExoAuth;
				EndPoint = $Uri;
				ResponseFormat = 'clixml';
				Command = 'Get-Label';
				Method = "POST";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			#Get label
			$sensitivity_labels = Get-PSExoAdminApiObject @p
		}
	}
	end {
		if ($null -ne $sensitivity_labels) {
			$sensitivity_labels.PSObject.TypeNames.Insert(0,'Monkey365.SecurityCompliance.sensitivity_labels')
			[pscustomobject]$obj = @{
				Data = $sensitivity_labels;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_secomp_sensitivity_labels = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Security and Compliance sensitivity labels",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('SecCompSensitivityLabelsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









