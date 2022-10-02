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


function Get-MonkeyTeamsNotificationsFeedsPolicy {
<#
        .SYNOPSIS
		Plugin to get information about notifications and feed policy in Teams

        .DESCRIPTION
		Plugin to get information about notifications and feed policy in Teams

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyTeamsNotificationsFeedsPolicy
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
		#Plugin metadata
		$monkey_metadata = @{
			Id = "teams06";
			Provider = "Microsoft365";
			Title = "Plugin to get information about notifications and feed policy in Teams";
			Group = @("MicrosoftTeams");
			ServiceName = "Microsoft Teams notification policies";
			PluginName = "Get-MonkeyTeamsNotificationsFeedsPolicy";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Getting environment
		$Environment = $O365Object.Environment
		#Get Access Token from Teams
		$access_token = $O365Object.auth_tokens.Teams
		$notification_settings = $null
	}
	process {
		if ($null -ne $access_token) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Microsoft 365 Teams: Notifications and feeds policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('TeamsOrgSettings');
			}
			Write-Information @msg
			$params = @{
				Authentication = $access_token;
				InternalPath = 'PowerShell';
				ObjectType = "TeamsNotificationAndFeedsPolicy";
				AdminDomain = 'common';
				Environment = $Environment;
				Method = "GET";
			}
			$notification_settings = Get-TeamsObject @params
		}
	}
	end {
		if ($notification_settings) {
			$notification_settings.PSObject.TypeNames.Insert(0,'Monkey365.Teams.NotificationPolicy')
			[pscustomobject]$obj = @{
				Data = $notification_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_teams_notification_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft 365 Teams: Notifications and feeds policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('TeamsOrgSettingsEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
