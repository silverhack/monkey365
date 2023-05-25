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
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeySharePointOnlineSiteAccessRequest";
			ApiType = $null;
			Title = "Plugin to get information about SPS access requests";
			Group = @("SharePointOnline");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
        if($null -eq $O365Object.spoWebs){
            break
        }
		#Get Access Token from SPO
		$sps_auth = $O365Object.auth_tokens.SharePointOnline
        #set generic list
        $all_external_access = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online site access requests",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('SPSAccessRequestsInfo');
		}
        Write-Information @msg
        foreach($web in $O365Object.spoWebs){
            $p = @{
                Web = $web;
                Authentication = $sps_auth;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $site_access = Get-MonkeyCSOMSiteAccessRequest @p
            if($site_access){
                #Add to list
                foreach($sa in $site_access){
                    [void]$all_external_access.Add($sa)
                }
            }
        }

	}
	end {
		if ($all_external_access) {
			$all_external_access.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Site.AccessRequests')
			[pscustomobject]$obj = @{
				Data = $all_external_access;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_site_access_requests = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online Site access requests",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.Verbose;
				Tags = @('SPSAccessRequestEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}




