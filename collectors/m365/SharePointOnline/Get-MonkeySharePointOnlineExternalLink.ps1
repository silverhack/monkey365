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
		Collector to get information about O365 Sharepoint Online external links

        .DESCRIPTION
		Collector to get information about O365 Sharepoint Online external links

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
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "sps0001";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeySharePointOnlineExternalLink";
			ApiType = "CSOM";
			description = "Collector to get information about O365 Sharepoint Online external links";
			Group = @(
				"SharePointOnline"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"o365_spo_sharing_links"
			);
			dependsOn = @(

			);
		}
		#Get config
		try {
            #Splat params
            $pWeb = @{
                Authentication = $O365Object.auth_tokens.SharePointOnline;
                Recurse = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Subsites.Recursive);
                Limit = $O365Object.internal_config.o365.SharePointOnline.Subsites.Depth;
                InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
            }
            #Splat params
            $pExternal = @{
                Authentication = $O365Object.auth_tokens.SharePointOnline;
                Filter = $O365Object.internal_config.o365.SharePointOnline.SharingLinks.Include;
                InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
            }

		}
		catch {
			$msg = @{
				MessageData = ($message.MonkeyInternalConfigError);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'verbose';
				InformationAction = $O365Object.InformationAction;
				Tags = @('Monkey365ConfigError');
			}
			Write-Verbose @msg
			#Splat params
            $pWeb = @{
                Authentication = $O365Object.auth_tokens.SharePointOnline
                InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
            }
            #Splat params
            $pExternal = @{
                Authentication = $O365Object.auth_tokens.SharePointOnline;
                InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
            }
		}
        #Set generic list
		$all_sharing_links = [System.Collections.Generic.List[System.Object]]::new()
        $allWebs = [System.Collections.Generic.List[System.Object]]::new()
	}
	Process {
        if($null -ne $O365Object.spoSites){
		    $msg = @{
			    MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"SharePoint Online sharing links",$O365Object.TenantID);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('SPSSharingLinkInfo');
		    }
		    Write-Information @msg
            @($O365Object.spoSites).ForEach(
                {
                    $_Web = $_.Url | Get-MonkeyCSOMWeb @pWeb;
                    if($_Web){
                        [void]$allWebs.Add($_Web);
                    }
                }
            )
            $sharingLinks = $allWebs.GetEnumerator() | Get-MonkeyCSOMExternalLink @pExternal
            foreach($eLink in @($sharingLinks)){
                [void]$all_sharing_links.Add($eLink);
            }
        }
	}
	End {
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
				Verbose = $O365Object.Verbose;
				Tags = @('SPSSharingLinkEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}







