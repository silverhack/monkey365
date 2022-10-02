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


function Get-MonkeyEXORoleManagement {
<#
        .SYNOPSIS
		Plugin to get information about management roles in Exchange Online

        .DESCRIPTION
		Plugin to get information about management roles in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXORoleManagement
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
			Id = "exo0031";
			Provider = "Microsoft365";
			Title = "Plugin to get information about management roles in Exchange Online";
			Group = @("ExchangeOnline");
			ServiceName = "Exchange Online RBAC";
			PluginName = "Get-MonkeyEXORoleManagement";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$exo_auth = $O365Object.auth_tokens.ExchangeOnline
		#Check if already connected to Exchange Online
		$exo_session = Test-EXOConnection
		#Get switch
		$getExoGroups = [System.Convert]::ToBoolean($O365Object.internal_config.o365.ExchangeOnline.GetExchangeGroups)
		$exo_role_groups = $null
	}
	process {
		if ($exo_session -and $exo_auth -and $getExoGroups) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Exchange Online role management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('ExoRoleManagementInfo');
			}
			Write-Information @msg
			#Getting all role groups from Exchange Online
			$exo_role_groups = Get-ExoMonkeyRoleGroup
			#Getting members
			if ($exo_role_groups) {
				#Set new vars
				$vars = @{
					"O365Object" = $O365Object;
					"WriteLog" = $WriteLog;
					'Verbosity' = $Verbosity;
					'InformationAction' = $InformationAction;
				}
				$param = @{
					ScriptBlock = { Get-PSExoUser -user $_.user };
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
				foreach ($role_group in $exo_role_groups) {
					if ($role_group.Members.Count -gt 0) {
						#Clone values
						$members = $role_group.Members.Clone()
						#Clear members
						$role_group.Members.Clear()
						#Get objects
						foreach ($member in $members) {
							$obj = @{ user = $member } | Invoke-MonkeyJob @param
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
								$group_object = Get-ExoMonkeyGroup -Identity $member -ErrorAction Ignore
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
		if ($exo_role_groups) {
			$exo_role_groups.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.RoleManagement')
			[pscustomobject]$obj = @{
				Data = $exo_role_groups;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_role_management = $obj
		}
		elseif ($getExoGroups -eq $false) {
			$msg = @{
				MessageData = ("EXO groups disabled in configuration file for {0}",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'debug';
				InformationAction = $InformationAction;
				Tags = @('ExoRoleManagementDisabled');
			}
			Write-Debug @msg
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online role management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('ExoRoleManagementEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
