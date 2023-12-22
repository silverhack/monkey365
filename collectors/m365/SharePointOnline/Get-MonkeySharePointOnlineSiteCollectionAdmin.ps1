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


function Get-MonkeySharePointOnlineSiteCollectionAdmin {
<#
        .SYNOPSIS
		Collector to get information about SPS site collection admins

        .DESCRIPTION
		Collector to get information about SPS site collection admins

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineSiteCollectionAdmin
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
		#Collector metadata
		$monkey_metadata = @{
			Id = "sps0005";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeySharePointOnlineSiteCollectionAdmin";
			ApiType = "CSOM";
			description = "Collector to get information about SPS site collection admins";
			Group = @(
				"SharePointOnline"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"o365_spo_site_admins"
			);
			dependsOn = @(

			);
		}
		if ($null -eq $O365Object.spoWebs) {
			break
		}
		#Get Access Token from SPO
		$sps_auth = $O365Object.auth_tokens.SharePointOnline
		#set generic list
		$all_site_admins = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Sharepoint Online site collection admins",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('SPSSiteCollectionAdminInfo');
		}
		Write-Information @msg
		foreach ($web in $O365Object.spoWebs) {
			$p = @{
				Web = $web;
				Authentication = $sps_auth;
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			$site_admins = Get-MonkeyCSOMSiteCollectionAdministrator @p
			if ($site_admins) {
				#Add to list
				foreach ($site_admin in $site_admins) {
					[void]$all_site_admins.Add($site_admin)
				}
			}
		}
	}
	end {
		if ($all_site_admins) {
			$all_site_admins.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.SiteCollection.Admins')
			[pscustomobject]$obj = @{
				Data = $all_site_admins;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_site_admins = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online External Users",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('SPSExternalUsersEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}







