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

function Get-MonkeyADDirectoryRole {
<#
        .SYNOPSIS
		Collector to get Directoryroles from Microsoft Entra ID
        https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles

        .DESCRIPTION
		Collector to get Directoryroles from Microsoft Entra ID
        https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADDirectoryRole
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
			Id = "aad0005";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyADDirectoryRole";
			ApiType = "Graph";
			description = "Collector to get Directoryroles from Microsoft Entra ID";
			Group = @(
				"EntraID"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_directory_roles";
				"aad_role_assignment"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		$all_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.Graph
		$TmpDirectoryRoles = @()
		#Get Config
		try {
			$aadConf = $O365Object.internal_config.entraId.Provider.Graph
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
			break
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID Directory Roles",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureGraphDirectoryRoles');
		}
		Write-Information @msg
		#Get Directory roles
		$params = @{
			Authentication = $AADAuth;
			ObjectType = "directoryRoles";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			APIVersion = $aadConf.api_version;
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$directory_roles = Get-MonkeyGraphObject @params
		if ($directory_roles) {
			$msg = @{
				MessageData = ($message.MonkeyResponseCountMessage -f $directory_roles.Count);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('AzureGraphDirectoryRolesCount');
			}
			Write-Information @msg
			foreach ($dr in $directory_roles) {
				$params = @{
					Authentication = $AADAuth;
					ObjectType = "directoryRoles";
					objectId = $dr.objectId;
					Relationship = 'members';
					ObjectDisplayName = $dr.displayName;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
					APIVersion = $aadConf.api_version;
					InformationAction = $O365Object.InformationAction;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
				}
				$users_count = Get-MonkeyGraphLinkedObject @params -GetLinks
				if ($users_count.url) {
					$dr | Add-Member -Type NoteProperty -Name Members -Value $users_count.url.Count
				}
				else {
					$dr | Add-Member -Type NoteProperty -Name Members -Value 0
				}
				$TmpDirectoryRoles += $dr
				#Getting users from Directory roles
				$params = @{
					Authentication = $AADAuth;
					ObjectType = "directoryRoles";
					objectId = $dr.objectId;
					Relationship = 'members';
					ObjectDisplayName = $dr.displayName;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
					APIVersion = $aadConf.api_version;
					InformationAction = $O365Object.InformationAction;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
				}
				$Users = Get-MonkeyGraphLinkedObject @params
				#Add to Array
				if ($Users) {
					$param = @{
						ScriptBlock = { Get-MonkeyGraphAADUser -UserId $_.objectId };
						Runspacepool = $O365Object.monkey_runspacePool;
						ReuseRunspacePool = $true;
						Debug = $O365Object.VerboseOptions.Debug;
						Verbose = $O365Object.VerboseOptions.Verbose;
						MaxQueue = $O365Object.MaxQueue;
						BatchSleep = $O365Object.BatchSleep;
						BatchSize = $O365Object.BatchSize;
					}
					$Users | Invoke-MonkeyJob @param | ForEach-Object {
						if ($_) {
							$_ | Add-Member -Type NoteProperty -Name MemberOf -Value $dr.displayName -Force
							$_ | Add-Member -Type NoteProperty -Name MemberOfDescription -Value $dr.description -Force
							$_ | Add-Member -Type NoteProperty -Name roleTemplateId -Value $dr.roleTemplateId -Force
							[void]$all_users.Add($_)
						}
					}
				}
			}
		}
	}
	end {
		if ($TmpDirectoryRoles) {
			$TmpDirectoryRoles.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.DirectoryRoles')
			[pscustomobject]$obj = @{
				Data = $TmpDirectoryRoles;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_directory_roles = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Directory roles",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'verbose';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureGraphUsersEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		if ($all_users) {
			$all_users.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.RoleAssignment')
			[pscustomobject]$obj = @{
				Data = $all_users;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_role_assignment = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID role assignment",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'verbose';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureGraphUsersEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}





