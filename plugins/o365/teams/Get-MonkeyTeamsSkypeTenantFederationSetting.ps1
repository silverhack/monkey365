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


function Get-MonkeyTeamsSkypeTenantFederationSetting {
<#
        .SYNOPSIS
		Plugin to get information about Teams Tenant federation settings (Skype)

        .DESCRIPTION
		Plugin to get information about Teams Tenant federation settings (Skype)

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyTeamsSkypeTenantFederationSetting
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
			Id = "teams10";
			Provider = "Microsoft365";
			Title = "Plugin to get information about Teams Tenant federation settings (Skype)";
			Group = @("MicrosoftTeams");
			ServiceName = "Microsoft Teams Skype Tenant Federation Settings";
			PluginName = "Get-MonkeyTeamsSkypeTenantFederationSetting";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Getting environment
		$Environment = $O365Object.Environment
		#Get Access Token from Teams
		$access_token = $O365Object.auth_tokens.Teams
		$fed_settings = $null
	}
	process {
		if ($null -ne $access_token) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Microsoft 365 Teams: Skype tenant federation settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('TeamsTenantFederationSettings');
			}
			Write-Information @msg
			if ($null -ne $O365Object.Tenant.MyDomain.id) {
				$domain = $O365Object.Tenant.MyDomain.id
			}
			else {
				$domain = 'common'
			}
			$params = @{
				Authentication = $access_token;
				InternalPath = 'SkypePolicy';
				ObjectType = "configurations/TenantFederationSettings";
				AdminDomain = $domain;
				Environment = $Environment;
				Method = "GET";
			}
			$fed_settings = Get-TeamsObject @params
		}
	}
	end {
		if ($fed_settings) {
			$fed_settings.PSObject.TypeNames.Insert(0,'Monkey365.Teams.Skype.FederationSettings')
			[pscustomobject]$obj = @{
				Data = $fed_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_teams_skype_federation_settings = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft 365 Teams: Skype tenant federation settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('TeamsTenantFederationSettingsEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
