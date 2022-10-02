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


function Get-MonkeyEXOProtectionAlert {
<#
        .SYNOPSIS
		Plugin to get information about protection alert in Exchange Online

        .DESCRIPTION
		Plugin to get information about protection alert in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOProtectionAlert
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		$exo_protection_alert = $null
		#Plugin metadata
		$monkey_metadata = @{
			Id = "purv002";
			Provider = "Microsoft365";
			Title = "Plugin to get information about protection alert in Exchange Online";
			Group = @("PurView");
			ServiceName = "PurView Protection Alert";
			PluginName = "Get-MonkeyEXOProtectionAlert";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Check if already connected to Exchange Online Compliance Center
		$exo_session = Test-EXOConnection -ComplianceCenter
	}
	process {
		if ($exo_session) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Security and Compliance protection alert",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('SecCompProtectionAlertInfo');
			}
			Write-Information @msg
			$exo_protection_alert = Get-ProtectionAlert
		}
	}
	end {
		if ($null -ne $exo_protection_alert) {
			$exo_protection_alert.PSObject.TypeNames.Insert(0,'Monkey365.SecurityCompliance.ProtectionAlert')
			[pscustomobject]$obj = @{
				Data = $exo_protection_alert;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_secomp_protection_alert = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online protection alert",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SecCompProtectionAlertResponse');
			}
			Write-Warning @msg
		}
	}
}
