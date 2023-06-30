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


function Get-MonkeySharePointOnlineExternalLink {
<#
        .SYNOPSIS
		Plugin to get information about O365 Sharepoint Online external links

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online external links

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineExternalLink
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
			Id = "sps0001";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeySharePointOnlineExternalLink";
			ApiType = "CSOM";
			Title = "Plugin to get information about O365 Sharepoint Online external links";
			Group = @("SharePointOnline");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
        if($null -eq $O365Object.spoWebs){
            break;
        }
        #Get config
        try{
            $FilterList = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.SharingLinks.Include)
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            #Filter to documents
            $FilterList = "Documents"
        }
        #Set generic list
        $all_sharing_links = New-Object System.Collections.Generic.List[System.Object]
        #Get auth
        $sps_auth = $O365Object.auth_tokens.SharePointOnline
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"SharePoint Online sharing links",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('SPSSharingLinkInfo');
		}
		Write-Information @msg
        foreach ($web in $O365Object.spoWebs){
            $p = @{
                Web = $web;
                Authentication = $sps_auth;
                ListNames = $FilterList;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $sharing_links = Get-MonkeyCSOMExternalLink @p
            if($sharing_links){
                foreach($link in @($sharing_links)){
                    #Add to list
                    [void]$all_sharing_links.Add($link)
                }
            }
        }
	}
	end {
		if ($all_sharing_links) {
			$all_sharing_links.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.SharingLinks')
			[pscustomobject]$obj = @{
				Data = $all_sharing_links;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_sharing_links = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "SharePoint Online sharing links",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
				Tags = @('SPSSharingLinkEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}




