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
		Collector to get information about management roles in Exchange Online Security & Compliance

        .DESCRIPTION
		Collector to get information about management roles in Exchange Online Security & Compliance

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
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		#Get EXO authentication
		#Collector metadata
		$monkey_metadata = @{
			Id = "purv011";
			Provider = "Microsoft365";
			Resource = "Purview";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeySeCompRoleManagement";
			ApiType = $null;
			description = "Collector to get information about management roles in Exchange Online Security \\\\\\\\\\\\\\\\& Compliance";
			Group = @(
				"Purview"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"o365_secomp_role_management"
			);
			dependsOn = @(
				"ExchangeOnline"
			);
		}
		#Get Backend Uri
		$Uri = $O365Object.SecCompBackendUri
		#Get authentication context
		$exo_auth = $O365Object.auth_tokens.ComplianceCenter
		#Get switch
		$getExoGroups = [System.Convert]::ToBoolean($O365Object.internal_config.o365.ExchangeOnline.GetPurViewGroups)
		$secomp_role_groups = $null
		#Get libs for runspace
		$rsOptions = Initialize-MonkeyScan -Provider Microsoft365 | Where-Object { $_.scanName -eq 'Purview' }
	}
	process {
		if ($exo_auth -and $getExoGroups -and $Uri) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Security & Compliance role management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('SecCompRoleManagementInfo');
			}
			Write-Information @msg
			#InitParams
			$p = @{
				Authentication = $ExoAuth;
				EndPoint = $Uri;
				ResponseFormat = 'clixml';
				Command = 'Get-RoleGroup';
				Method = "POST";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			#Getting all role groups from Security & Compliance
			$secomp_role_groups = Get-PSExoAdminApiObject @p
			#Getting members
			if ($secomp_role_groups) {
				#Set new vars
				$vars = $O365Object.runspace_vars
				$param = @{
					Command = "Get-PSExoUser";
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
				foreach ($role_group in $secomp_role_groups) {
					if ($role_group.members.Count -gt 0) {
						#Clone values
						$members = $role_group.members.Clone()
						#Clear members
						$role_group.members.Clear()
						#Get objects
						foreach ($member in $members) {
							$obj = Invoke-MonkeyJob @param -Arguments @{ User = $member; AuthenticationObject = $exo_auth }
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
								#InitParams
								$p = @{
									Authentication = $ExoAuth;
									EndPoint = $Uri;
									ResponseFormat = 'clixml';
									Command = ('Get-Group -Identity {0} -ErrorAction Ignore' -f $member);
									Method = "POST";
									InformationAction = $O365Object.InformationAction;
									Verbose = $O365Object.Verbose;
									Debug = $O365Object.Debug;
								}
								#Getting all role groups from Security & Compliance
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
				MessageData = ("EXO groups for PurView disabled in configuration file for {0}" -f $O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('SecCompRoleManagementDisabled');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Security & Compliance role management",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('SecCompRoleManagementEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







