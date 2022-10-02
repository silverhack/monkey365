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


function Get-MonkeySharePointOnlineSiteAccessRequest {
<#
        .SYNOPSIS
		Plugin to get information about SPS access requests

        .DESCRIPTION
		Plugin to get information about SPS access requests

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineSiteAccessRequest
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
			Id = "sps0004";
			Provider = "Microsoft365";
			Title = "Plugin to get information about SPS access requests";
			Group = @("SharepointOnline");
			ServiceName = "SharePoint Online Site access requests";
			PluginName = "Get-MonkeySharePointOnlineSiteAccessRequest";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Access Token from SPO
		$sps_auth = $O365Object.auth_tokens.SharePointOnline
		$all_access_requests = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online site access requests",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('SPSAccessRequestsInfo');
		}
		Write-Information @msg
		#Get all webs for user
		$allowed_sites = Get-MonkeySPSWebsForUser
		foreach ($site in $allowed_sites) {
			#Getting Lists from Web
			$msg = @{
				MessageData = ($message.SPSGetListsForWeb -f $site.url);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('SPSExternalUsersInfo');
			}
			Write-Information @msg
			$param = @{
				Authentication = $sps_auth;
				clientObject = $site;
				Properties = 'Lists';
				executeQuery = $true;
				endpoint = $site.url;
			}
			$all_lists = Get-MonkeySPSProperty @param
			if ($null -ne $all_lists) {
				$access_requests_lists = $all_lists.Lists | Where-Object { $_.Title -eq 'Access Requests' }
				if ($null -ne $access_requests_lists) {
					foreach ($access_requests_list in $access_requests_lists) {
						#Getting access requests
						$msg = @{
							MessageData = ($message.SPSCheckSiteAccessRequests -f $site.url);
							callStack = (Get-PSCallStack | Select-Object -First 1);
							logLevel = 'verbose';
							InformationAction = $InformationAction;
							Tags = @('SPSAccessRequestInfo');
						}
						Write-Verbose @msg
						$param = @{
							Authentication = $sps_auth;
							list = $access_requests_list;
							endpoint = $site.url;
						}
						$list = Get-MonkeySPSListItem @param
						if ($null -ne $list) {
							foreach ($access in $list) {
								$all_access_requests += New-Object PSObject -Property ([Ordered]@{
										Title = $access.Title
										RequestedObjectUrl = $access.RequestedObjectUrl.url
										RequestedObjectTitle = $access.RequestedObjectTitle
										RequestedBy = $access.RequestedBy
										RequestedFor = $access.RequestedFor
										RequestDate = $access.RequestDate
										Expires = $access.Expires
										status = [ChangeRequestStatus]$access.status
										permissionType = $access.permissionType
										IsInvitation = $access.IsInvitation
									})
							}
						}
					}
				}
			}
		}
	}
	end {
		if ($all_access_requests) {
			$all_access_requests.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Site.AccessRequests')
			[pscustomobject]$obj = @{
				Data = $all_access_requests;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_site_access_requests = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online Site access requests",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SPSAccessRequestEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
