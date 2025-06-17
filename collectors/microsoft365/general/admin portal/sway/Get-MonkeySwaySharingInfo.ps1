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


function Get-MonkeySwaySharingInfo {
<#
        .SYNOPSIS
		Collector to get sharing information from Microsoft Sway

        .DESCRIPTION
		Collector to get sharing information from Microsoft Sway

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySwaySharingInfo
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
		$sharing_settings = $null;
		#Collector metadata
		$monkey_metadata = @{
			Id = "m365admin001";
			Provider = "Microsoft365";
			Resource = "MicrosoftSway";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeySwaySharingInfo";
			ApiType = $null;
			description = "Collector to get sharing information from Microsoft Sway";
			Group = @(
				"AdminPortal"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_sway_sharing_settings"
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
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Sway. Sharing Settings",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('SwaySharingInfo');
		}
		if ($null -ne $Authentication) {
			$params = @{
				Authentication = $Authentication;
				Environment = $Environment;
				InternalPath = 'appsettings';
				ObjectType = 'sway';
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			#call admin api
			$sharing_settings = Get-MonkeyM365AdminObject @params
		}
		else {
			$msg = @{
				MessageData = ("Unable to get sharing's information from Microsoft Sway");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $O365Object.InformationAction;
				Tags = @('SwaySharingInfoWarning');
			}
			Write-Warning @msg
		}
	}
	end {
		if ($null -ne $sharing_settings) {
			$sharing_settings.PSObject.TypeNames.Insert(0,'Monkey365.Swat.Sharing')
			[pscustomobject]$obj = @{
				Data = $sharing_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_sway_sharing_settings = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Sway. Sharing Settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('SwaySharingInfoEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}









