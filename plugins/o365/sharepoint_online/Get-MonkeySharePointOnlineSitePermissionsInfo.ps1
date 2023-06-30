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
		Plugin to get information about O365 Sharepoint Online site permissions

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online site permissions

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
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		#Plugin metadata
		$monkey_metadata = @{
			Id = "sps0006";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeySharePointOnlineSitePermissionsInfo";
			ApiType = "CSOM";
			Title = "Plugin to get information about Sharepoint Online site permissions";
			Group = @("SharePointOnline");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
        try{
            $scanFolders = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.ScanFolders)
            $scanFiles = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.ScanFiles)
            $inheritedForSite = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Permissions.Site.IncludeInheritedPermissions)
            $inheritedForList = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Permissions.Lists.IncludeInheritedPermissions)
            $inheritedForFolder = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Permissions.Folders.IncludeInheritedPermissions)
            $inheritedForItem = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Permissions.Items.IncludeInheritedPermissions)
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
            #Set to false
            $scanFolders = $false
            $scanFiles = $false
            $inheritedForSite = $false
            $inheritedForList = $false
            $inheritedForFolder = $false
            $inheritedForItem = $false
        }
		if($null -eq $O365Object.spoWebs){
            break;
        }
        #Set generic list
        $all_perms = New-Object System.Collections.Generic.List[System.Object]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online site permissions",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('SPSSitePermsInfo');
		}
		Write-Information @msg
        foreach($Web in $O365Object.spoWebs){
            $p = [ordered]@{
                Authentication = $O365Object.auth_tokens.SharePointOnline;
                Web = $web;
                ScanFiles = $scanFiles;
                ScanFolders = $scanFolders;
                SiteInheritedPermission = $inheritedForSite;
                ListInheritedPermission = $inheritedForList;
                FolderInheritedPermission = $inheritedForFolder;
                FileInheritedPermission = $inheritedForItem;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $perms = Invoke-MonkeyCSOMSitePermission @p
            if($perms){
                [void]$all_perms.Add($perms)
            }
        }
	}
	end {
		if ($all_perms) {
			$all_perms.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Permissions')
			[pscustomobject]$obj = @{
				Data = $all_perms;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_permissions = $obj
		}
		else {
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




