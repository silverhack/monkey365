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



function Get-MonkeyADPortalDirectoryRoleInfo {
<#
        .SYNOPSIS
		Plugin to get Directoryroles from Azure AD
        https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles

        .DESCRIPTION
		Plugin to get Directoryroles from Azure AD
        https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADPortalDirectoryRoleInfo
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
		$AADConfig = $O365Object.internal_config.azuread
		#Plugin metadata
		$monkey_metadata = @{
			Id = "aad0005";
			Provider = "AzureAD";
			Title = "Plugin to get Directoryroles from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD Directory Role";
			PluginName = "Get-MonkeyADPortalDirectoryRoleInfo";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$Environment = $O365Object.Environment
		#Get Azure Graph Auth
		$AADGraphAuth = $O365Object.auth_tokens.Graph
		#create array
		$tmp_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
		$all_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
		#Get Config
		$use_azure_portal = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.useAzurePortalAPI)
		$dump_users_with_graph_api = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.dumpAdUsersWithInternalGraphAPI)
		#Get Auth Type
		$auth_type = $O365Object.AuthType
		#Generate vars
		$vars = @{
			"O365Object" = $O365Object;
			"WriteLog" = $WriteLog;
			'Verbosity' = $Verbosity;
			'InformationAction' = $InformationAction;
			"all_users" = $tmp_users;
		}
		$TmpDirectoryRoles = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD DirectoryRoles",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalDirectoryRoles');
		}
		Write-Information @msg
		#Get Directory roles
		$params = @{
			Authentication = $AADGraphAuth;
			ObjectType = "directoryRoles";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			APIVersion = $AADConfig.api_version;
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
					Authentication = $AADGraphAuth;
					ObjectType = "directoryRoles";
					objectId = $dr.objectId;
					Relationship = 'members';
					ObjectDisplayName = $dr.displayName;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
					APIVersion = $AADConfig.api_version;
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
					Authentication = $AADGraphAuth;
					ObjectType = "directoryRoles";
					objectId = $dr.objectId;
					Relationship = 'members';
					ObjectDisplayName = $dr.displayName;
					Environment = $Environment;
					ContentType = 'application/json';
					Method = "GET";
					APIVersion = $AADConfig.api_version;
				}
				$Users = Get-MonkeyGraphLinkedObject @params
				#Add to Array
				if ($Users) {
					$Jobparam = @{
						ScriptBlock = { Get-MonkeyADPortalDetailedUser -user $_ };
						ImportCommands = $O365Object.LibUtils;
						ImportVariables = $vars;
						ImportModules = $O365Object.runspaces_modules;
						StartUpScripts = $O365Object.runspace_init;
						ThrowOnRunspaceOpenError = $true;
						Debug = $O365Object.VerboseOptions.Debug;
						Verbose = $O365Object.VerboseOptions.Verbose;
						Throttle = $O365Object.nestedRunspaceMaxThreads;
						MaxQueue = $O365Object.MaxQueue;
						BatchSleep = $O365Object.BatchSleep;
						BatchSize = $O365Object.BatchSize;
					}
					if ($dump_users_with_graph_api) {
						$Jobparam.ScriptBlock = { Get-AADDetailedUser -user $_ }
					}
					elseif (-not $dump_users_with_graph_api -and $use_azure_portal -and $auth_type -notlike "C*") {
						#Get internal function
						$Jobparam.ScriptBlock = { Get-MonkeyADPortalDetailedUser -user $_ }
					}
					else {
						#Get internal function
						$Jobparam.ScriptBlock = { Get-AADDetailedUser -user $_ }
					}
					<#
                    $Users | Invoke-MonkeyJob @param -Debug
                    if($tmp_users){
                        $tmp_users |ForEach-Object {$_ | Add-Member -type NoteProperty -name MemberOf -Value $dr.displayName -Force}
                        #$tmp_users = $tmp_users | Select-Object $AADConfig.DirectoryRolesFilter
                        $tmp_users = $tmp_users | Where-Object {$null -ne $_.objectId}
                        $DirectoryRolesUsers+=$tmp_users
                    }
                    #Set new array
                    $vars.all_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
                    #>
					$Users | Invoke-MonkeyJob @Jobparam | ForEach-Object {
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
			$TmpDirectoryRoles.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.DirectoryRoles')
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
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureGraphUsersEmptyResponse');
			}
			Write-Warning @msg
		}
		if ($all_users) {
			[pscustomobject]$obj = @{
				Data = $all_users;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_directory_user_roles = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Directory user roles",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalUsersEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
