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


function Get-MonkeySharePointOnlineOrphanedUser {
<#
        .SYNOPSIS
		Plugin to get information about SPS orphaned users and groups

        .DESCRIPTION
		Plugin to get information about SPS orphaned users and groups

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineOrphanedUser
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
			Id = "sps0003";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeySharePointOnlineOrphanedUser";
			ApiType = $null;
			Title = "Plugin to get information about SharePoint Online orphaned users and groups";
			Group = @("SharePointOnline");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
        if($null -eq $O365Object.spoWebs){
            break
        }
		#Get Access Token for Sharepoint
		$sps_auth = $O365Object.auth_tokens.SharePointOnline
        #set generic lists
        $sps_orphaned_users = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
        $sps_orphaned_groups = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online orphaned users",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('SPSOrphanedUsersInfo');
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
            $orphan_objects = Get-MonkeyCSOMOrphanedUser @p
            if($orphan_objects){
                $orphaned_users = $orphan_objects | Where-Object {$_.principalType -eq [principalType]::User}
                $orphaned_groups = $orphan_objects | Where-Object {$_.principalType -eq [principalType]::SecurityGroup}
                if($orphaned_users){
                    #Add to list
                    foreach($ou in $orphaned_users){
                        [void]$sps_orphaned_users.Add($ou)
                    }
                }
                if($orphaned_groups){
                    #Add to list
                    foreach($og in $orphaned_groups){
                        [void]$sps_orphaned_groups.Add($og)
                    }
                }
            }
        }
	}
	end {
		if ($sps_orphaned_users) {
			$sps_orphaned_users.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Tenant.OrphanedUsers')
			[pscustomobject]$obj = @{
				Data = $sps_orphaned_users;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_orphaned_users = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online Orphaned Users",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
                Tags = @('SPSOrphanedUsersEmptyResponse');
			}
			Write-Verbose @msg
		}
		if ($sps_orphaned_groups) {
			$sps_orphaned_groups.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Tenant.OrphanedGroups')
			[pscustomobject]$obj = @{
				Data = $sps_orphaned_groups;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_orphaned_groups = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online Orphaned Groups",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
                Tags = @('SPSOrphanedGroupsEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}




