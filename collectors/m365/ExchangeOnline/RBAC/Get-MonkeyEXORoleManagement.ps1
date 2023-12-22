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
		Collector to get information about management roles in Exchange Online

        .DESCRIPTION
		Collector to get information about management roles in Exchange Online

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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","",Scope = "Function")]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		#Get EXO authentication
		#Collector metadata
		$monkey_metadata = @{
			Id = "exo0031";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEXORoleManagement";
			ApiType = "ExoApi";
			description = "Collector to get information about management roles in Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"o365_exo_role_management"
			);
			dependsOn = @(

			);
		}
		$ExoAuth = $O365Object.auth_tokens.ExchangeOnline
		#Get Environment
		$Environment = $O365Object.Environment
		#Get switch
		$getExoGroups = [System.Convert]::ToBoolean($O365Object.internal_config.o365.ExchangeOnline.GetExchangeGroups)
		$exo_role_groups = $null
		#Set Empty GUID
		$EmptyGuid = [System.Guid]::Empty
		#Get libs for runspace
		$rsOptions = Initialize-MonkeyScan -Provider Microsoft365 | Where-Object { $_.scanName -eq 'ExchangeOnline' }
	}
	process {
		if ($ExoAuth -and $getExoGroups) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Online role management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoRoleManagementInfo');
			}
			Write-Information @msg
			#Getting all role groups from Exchange Online
			$p = @{
				Authentication = $ExoAuth;
				Environment = $Environment;
				ResponseFormat = 'clixml';
				Command = 'Get-RoleGroup';
				Method = "POST";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			$exo_role_groups = Get-PSExoAdminApiObject @p
			#Getting members
			if ($exo_role_groups) {
				#Set new vars
				$vars = $O365Object.runspace_vars
				$param = @{
					ScriptBlock = { Get-PSExoUser -user $_ };
					ImportCommands = $rsOptions.libCommands;
					ImportVariables = $vars;
					ImportModules = $O365Object.runspaces_modules;
					StartUpScripts = $O365Object.runspace_init;
					ThrowOnRunspaceOpenError = $true;
					Debug = $O365Object.Debug;
					Verbose = $O365Object.Verbose;
					Throttle = $O365Object.nestedRunspaceMaxThreads;
					MaxQueue = $O365Object.MaxQueue;
					BatchSleep = $O365Object.BatchSleep;
					BatchSize = $O365Object.BatchSize;
				}
				foreach ($role_group in $exo_role_groups) {
					if ($role_group.members.Count -gt 0) {
						#Clone values
						$members = $role_group.members.Clone()
						#Clear members
						$role_group.members.Clear()
						#Get objects
						foreach ($member in $members) {
							#$isValidGuid = [System.Guid]::TryParse($member,[System.Management.Automation.PSReference]$EmptyGuid)
							$obj = $member | Invoke-MonkeyJob @param
							if ($obj) {
								[void]$role_group.members.Add($obj)
							}
							else {
								$msg = @{
									MessageData = ("Potentially group detected in role member");
									callStack = (Get-PSCallStack | Select-Object -First 1);
									logLevel = 'verbose';
									InformationAction = $O365Object.InformationAction;
									Verbose = $O365Object.Verbose;
									Tags = @('ExoRoleManagementInfo');
								}
								Write-Verbose @msg
								#Potentially group detected
								$p.Command = ('Get-Group -Identity {0} -ErrorAction SilentlyContinue' -f $member)
								$group_object = Get-PSExoAdminApiObject @p
								if ($null -ne $group_object) {
									[void]$role_group.members.Add($group_object)
								}
								else {
									$msg = @{
										MessageData = ("Unknown object: {0}" -f $member);
										callStack = (Get-PSCallStack | Select-Object -First 1);
										logLevel = 'verbose';
										InformationAction = $O365Object.InformationAction;
										Verbose = $O365Object.Verbose;
										Tags = @('ExoRoleManagementInfo');
									}
									Write-Verbose @msg
									#Unknown object (Service account? MS Global group?)
									$unknownPsObject = New-Object -TypeName PsObject -Property @{
										displayName = $member;
										ObjectCategory = $null;
									}
									[void]$role_group.members.Add($unknownPsObject);
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
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoRoleManagementDisabled');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online role management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoRoleManagementEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







