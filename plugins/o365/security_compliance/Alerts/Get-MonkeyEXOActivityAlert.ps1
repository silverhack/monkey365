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


function Get-MonkeyEXOActivityAlert {
<#
        .SYNOPSIS
		Plugin to get information about activity alerts from PurView

        .DESCRIPTION
		Plugin to get information about activity alerts from PurView

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOActivityAlert
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
		$activity_alerts = $null;
		#Plugin metadata
		$monkey_metadata = @{
			Id = "purv001";
			Provider = "Microsoft365";
			Title = "Plugin to get information about activity alerts from PurView";
			Group = @("PurView");
			ServiceName = "Microsoft PurView activity alerts";
			PluginName = "Get-MonkeyEXOActivityAlert";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$exo_session = Test-EXOConnection -ComplianceCenter
	}
	process {
		if ($null -ne $exo_session) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Security and Compliance activity alerts",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('SecCompActivityAlertsInfo');
			}
			Write-Information @msg
			#Get activity alerts
			$activity_alerts = Get-ActivityAlert
		}
	}
	end {
		if ($activity_alerts) {
			$activity_alerts.PSObject.TypeNames.Insert(0,'Monkey365.SecurityCompliance.ActivityAlerts')
			[pscustomobject]$obj = @{
				Data = $activity_alerts;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_secomp_activity_alerts = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Security and Compliance activity alerts",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SecCompActivityAlertsEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
