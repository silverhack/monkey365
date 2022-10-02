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


function Get-MonkeySeCompRoleManagement {
<#
        .SYNOPSIS
		Plugin to get information about management roles in Exchange Online Security & Compliance

        .DESCRIPTION
		Plugin to get information about management roles in Exchange Online Security & Compliance

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySeCompRoleManagement
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
		#Get EXO authentication
		#Plugin metadata
		$monkey_metadata = @{
			Id = "purv011";
			Provider = "Microsoft365";
			Title = "Plugin to get information about management roles in Exchange Online Security \u0026 Compliance";
			Group = @("PurView");
			ServiceName = "Microsoft PurView RBAC";
			PluginName = "Get-MonkeySeCompRoleManagement";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$exo_auth = $O365Object.auth_tokens.ComplianceCenter
		#Check if already connected to Security & Compliance
		$exo_session = Test-EXOConnection -ComplianceCenter
		#Get switch
		$getExoGroups = [System.Convert]::ToBoolean($O365Object.internal_config.o365.ExchangeOnline.GetPurViewGroups)
		$secomp_role_groups = $null
	}
	process {
		if ($exo_session -and $exo_auth -and $getExoGroups) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Security & Compliance role management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('SecCompRoleManagementInfo');
			}
			Write-Information @msg
			#Getting all role groups from Security & Compliance
			$secomp_role_groups = Get-RoleGroup
			#Getting members
			if ($secomp_role_groups) {
				#Set new vars
				$vars = @{
					"O365Object" = $O365Object;
					"WriteLog" = $WriteLog;
					'Verbosity' = $Verbosity;
					'InformationAction' = $InformationAction;
				}
				$param = @{
					ScriptBlock = { Get-PSExoUser -user $_.user -AuthenticationObject $_.AuthenticationObject };
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
				foreach ($role_group in $secomp_role_groups) {
					if ($role_group.Members.Count -gt 0) {
						#Clone values
						$members = $role_group.Members.Clone()
						#Clear members
						$role_group.Members.Clear()
						#Get objects
						foreach ($member in $members) {
							$obj = @{ user = $member; AuthenticationObject = $exo_auth } | Invoke-MonkeyJob @param
							if ($obj) {
								[void]$role_group.Members.Add($obj)
							}
							else {
								$msg = @{
									MessageData = ("Potentially group detected in role member");
									callStack = (Get-PSCallStack | Select-Object -First 1);
									logLevel = 'verbose';
									InformationAction = $InformationAction;
									Tags = @('ExoRoleManagementInfo');
								}
								Write-Verbose @msg
								#Potentially group detected
								$group_object = Get-Group -Identity $member -ErrorAction Ignore
								if ($null -ne $group_object) {
									[void]$role_group.Members.Add($group_object)
								}
								else {
									$msg = @{
										MessageData = ("Unknown object: {0}" -f $member);
										callStack = (Get-PSCallStack | Select-Object -First 1);
										logLevel = 'verbose';
										InformationAction = $InformationAction;
										Tags = @('ExoRoleManagementInfo');
									}
									Write-Verbose @msg
									#Unknown object (Service account? MS Global group?)
									$unknownPsObject = New-Object -TypeName PsObject -Property @{
										displayName = $member;
										ObjectCategory = $null;
									}
									[void]$role_group.Members.Add($unknownPsObject);
								}
							}
						}
					}
				}
			}
		}
	}
	end {
		if ($secomp_role_groups) {
			$secomp_role_groups.PSObject.TypeNames.Insert(0,'Monkey365.SecurityCompliance.RoleManagement')
			[pscustomobject]$obj = @{
				Data = $secomp_role_groups;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_secomp_role_management = $obj
		}
		elseif ($getExoGroups -eq $false) {
			$msg = @{
				MessageData = ("EXO groups for PurView disabled in configuration file for {0}",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'debug';
				InformationAction = $InformationAction;
				Tags = @('SecCompRoleManagementDisabled');
			}
			Write-Debug @msg
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Security & Compliance role management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SecCompRoleManagementEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
