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


function Get-MonkeySPSOrphanedUser {
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
            File Name	: Get-MonkeySPSOrphanedUser
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
			Title = "Plugin to get information about SPS orphaned users and groups";
			Group = @("SharepointOnline");
			ServiceName = "SharePoint Online orphaned objects";
			PluginName = "Get-MonkeySPSOrphanedUser";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Access Token for Sharepoint
		$sps_auth = $O365Object.auth_tokens.SharePointOnline
		#Set new array
		$sps_orphaned_users = @()
		$sps_orphaned_groups = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online orphaned users",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('SPSOrphanedUsersInfo');
		}
		Write-Information @msg
		#Get all webs for user
		$allowed_sites = Get-MonkeySPSWebsForUser
		#Getting users for each site
		foreach ($site in $allowed_sites) {
			$msg = @{
				MessageData = ("Getting orphaned users in {0}" -f $site.url);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('SPSOrphanedUsersInfo');
			}
			Write-Information @msg
			#body
			$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="52" ObjectPathId="5"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true"/><Property Name="Title" ScalarProperty="true"/><Property Name="LoginName" ScalarProperty="true"/><Property Name="Email" ScalarProperty="true"/><Property Name="IsShareByEmailGuestUser" ScalarProperty="true"/><Property Name="IsSiteAdmin" ScalarProperty="true"/><Property Name="UserId" ScalarProperty="true"/><Property Name="IsHiddenInUI" ScalarProperty="true"/><Property Name="PrincipalType" ScalarProperty="true"/><Property Name="AadObjectId" ScalarProperty="true"/><Property Name="UserPrincipalName" ScalarProperty="true"/><Property Name="Alerts"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Title" ScalarProperty="true"/><Property Name="Status" ScalarProperty="true"/></Properties></ChildItemQuery></Property><Property Name="Groups"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true"/><Property Name="Title" ScalarProperty="true"/><Property Name="LoginName" ScalarProperty="true"/></Properties></ChildItemQuery></Property></Properties></ChildItemQuery></Query></Actions><ObjectPaths><Property Id="5" ParentId="3" Name="SiteUsers"/><Property Id="3" ParentId="1" Name="Web"/><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current"/></ObjectPaths></Request>'
			#Set object metadata
			$objectMetadata = @{
				CheckValue = 1;
				isEqualTo = 52;
				GetValue = 2;
				ChildItems = '';
			}
			$param = @{
				Authentication = $sps_auth;
				Data = $body_data;
				objectMetadata = $objectMetadata;
				endpoint = $site.url;
			}
			#call SPS
			$raw_objects = Invoke-MonkeySPSDefaultUrlRequest @param
			if ($raw_objects) {
				#Convert values
				foreach ($element in $raw_objects) {
					$element.PrincipalType = [PrincipalType]$element.PrincipalType
				}
				$site_objects = $raw_objects | Where-Object {
					$_.Title.ToLower() -ne 'everyone' `
 						-and $_.Title.ToLower() -ne 'everyone except external users' `
 						-and $_.Title.ToLower() -ne "sharepoint app" `
 						-and $_.Title.ToLower() -ne "system account " `
 						-and $_.Title.ToLower() -ne "nt service\spsearch" `
 						-and $_.Title.ToLower() -ne "sharepoint service administrator" `
 						-and $_.Title.ToLower() -ne "global administrator" `
 						-and $null -ne $_.AadObjectId
				}
				if ($site_objects) {
					foreach ($object in $site_objects) {
						$object_id = $object.AadObjectId.NameId
						if ($null -ne $object_id) {
							if ($object.PrincipalType -eq 'User') {
								$user_status = Get-PSGraphUserById -user_id $object_id
								if ($null -eq $user_status) {
									$object | Add-Member NoteProperty -Name SiteUrl -Value $site.url
									$object | Add-Member NoteProperty -Name Site -Value $site
									$object | Add-Member NoteProperty -Name orphanedType -Value "deleted"
									#Add to array
									$sps_orphaned_users += $object
								}
								elseif ($null -ne $user_status -and $user_status.accountEnabled -eq $false) {
									$object | Add-Member NoteProperty -Name SiteUrl -Value $site.url
									$object | Add-Member NoteProperty -Name Site -Value $site
									$object | Add-Member NoteProperty -Name orphanedType -Value "disabled"
									#Add to array
									$sps_orphaned_users += $object
								}
							}
							elseif ($object.PrincipalType -eq 'SecurityGroup') {
								$group_status = Get-PSGraphGroupById -group_id $object_id
								if ($null -eq $group_status) {
									$object | Add-Member NoteProperty -Name SiteUrl -Value $site.url
									$object | Add-Member NoteProperty -Name Site -Value $site
									$object | Add-Member NoteProperty -Name orphanedType -Value "deleted"
									#Add to array
									$sps_orphaned_groups += $object
								}
							}
						}
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
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SPSOrphanedUsersEmptyResponse');
			}
			Write-Warning @msg
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
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SPSOrphanedGroupsEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
