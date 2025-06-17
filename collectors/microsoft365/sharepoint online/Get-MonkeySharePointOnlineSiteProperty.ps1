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


function Get-MonkeySharePointOnlineSiteProperty {
<#
        .SYNOPSIS
		Collector to extract information about O365 SharePoint Online site properties

        .DESCRIPTION
		Collector to extract information about O365 SharePoint Online site properties

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineSiteProperty
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	Begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "sps0010";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeySharePointOnlineSiteProperty";
			ApiType = "CSOM";
			description = "Collector to extract information about SharePoint Online site properties";
			Group = @(
				"SharePointOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_spo_sites_properties"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Set list
		$all_site_properties = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
	}
	Process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"SharePoint Online Site Properties",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('SPSTenantSites');
		}
		Write-Information @msg
		If ($O365Object.isSharePointAdministrator) {
			#Splat params
			$pSite = @{
				Authentication = $O365Object.auth_tokens.SharePointAdminOnline;
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
		}
		Else {
			#Splat params
			$pSite = @{
				Authentication = $O365Object.auth_tokens.SharePointAdminOnline;
				AsUser = $true;
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
		}
        If($null -ne $O365Object.spoSites){
		    @($O365Object.spoSites).ForEach({
				    $sp = $_ | Get-MonkeyCSOMSiteProperty @pSite
				    If ($sp) {
					    [void]$all_site_properties.Add($sp)
				    }
			    });
        }
        Else{
            $sp = Get-MonkeyCSOMSiteProperty @pSite
            If ($sp) {
				[void]$all_site_properties.Add($sp)
			}
        }
	}
	End {
		If ($all_site_properties) {
			$all_site_properties.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Sites')
			[pscustomobject]$obj = @{
				Data = $all_site_properties;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_sites_properties = $obj
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "SharePoint Online Site Properties",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('SPSTenantSitesEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}









