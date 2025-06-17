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


function Get-MonkeySharePointOnlineSitePermissionsInfo {
<#
        .SYNOPSIS
		Collector to get information about O365 Sharepoint Online site permissions

        .DESCRIPTION
		Collector to get information about O365 Sharepoint Online site permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineSitePermissionsInfo
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
			Id = "sps0006";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeySharePointOnlineSitePermissionsInfo";
			ApiType = "CSOM";
			description = "Collector to get information about Sharepoint Online site permissions";
			Group = @(
				"SharePointOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_spo_permissions"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get config
		try {
			#Splat params
			$pWeb = @{
				Authentication = $O365Object.auth_tokens.SharePointOnline;
				Recurse = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Subsites.Recursive);
				Limit = $O365Object.internal_config.o365.SharePointOnline.Subsites.Depth;
				Filter = $O365Object.internal_config.o365.SharePointOnline.SharingLinks.Include;
				IncludeLists = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.sitePermissionsOptions.IncludeLists);
				IncludeItems = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.sitePermissionsOptions.includeListItems);
				ExcludeFolders = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.sitePermissionsOptions.ExcludeFolders);
				IncludeInheritedPermission = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.sitePermissionsOptions.includeInheritedPermissions);
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
		}
		#Set generic list
		$all_perms = [System.Collections.Generic.List[System.Object]]::new()
        $abort = $true
	}
	Process {
		If ($null -ne $O365Object.spoSites) {
            $abort = $false
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Sharepoint Online site permissions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('SPSSitePermsInfo');
			}
			Write-Information @msg
			$perms = $O365Object.spoSites | Get-MonkeyCSOMSitePermission @pWeb
			foreach ($perm in @($perms).Where({ $null -ne $_ })) {
				[void]$all_perms.Add($perm);
			}
		}
	}
	End {
        If($abort -eq $false){
		    If ($all_perms) {
			    $all_perms.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Permissions')
			    [pscustomobject]$obj = @{
				    Data = $all_perms;
				    Metadata = $monkey_metadata;
			    }
			    $returnData.o365_spo_permissions = $obj
		    }
		    Else {
			    $msg = @{
				    MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online site permissions",$O365Object.TenantID);
				    callStack = (Get-PSCallStack | Select-Object -First 1);
				    logLevel = "verbose";
				    InformationAction = $O365Object.InformationAction;
				    Verbose = $O365Object.Verbose;
				    Tags = @('SPSSitePermissionsEmptyResponse');
			    }
			    Write-Verbose @msg
		    }
        }
	}
}









