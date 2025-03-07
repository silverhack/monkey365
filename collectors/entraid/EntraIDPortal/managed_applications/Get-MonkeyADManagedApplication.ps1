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


function Get-MonkeyADManagedApplication {
<#
        .SYNOPSIS
		Collector to get managed applications from Microsoft Entra ID

        .DESCRIPTION
		Collector to get managed applications from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADManagedApplication
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
		$azure_ad_managed_applications = $app_by_principalIds = $null
		#Collector metadata
		$monkey_metadata = @{
			Id = "aad0030";
			Provider = "EntraID";
			Resource = "EntraIDPortal";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyADManagedApplication";
			ApiType = "EntraIDPortal";
			description = "Collector to get managed applications from Microsoft Entra ID";
			Group = @(
				"EntraIDPortal"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_managed_app";
				"aad_managed_app_perms";
				"aad_managed_app_perms_byusers"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
		#create arrays
		$managed_apps = New-Object System.Collections.Generic.List[System.Object]
		$managed_apps_permissions = New-Object System.Collections.Generic.List[System.Object]
		$app_by_principalIds = New-Object System.Collections.Generic.List[System.Object]
		#Get vars
		$vars = $O365Object.runspace_vars
		try {
			$aadConf = $O365Object.internal_config.entraId.Provider.portal
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
		#Get libs for runspace
		$rsOptions = Initialize-MonkeyScan -Provider EntraID
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID managed applications",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzurePortalManagedApplications');
		}
		Write-Information @msg
		try {
			#POST DATA
			$post_data = '{"accountEnabled":null,"isAppVisible":null,"appListQuery":0,"top":100,"loadLogo":false,"putCachedLogoUrlOnly":true,"nextLink":"","usedFirstPartyAppIds":null,"__ko_mapping__":{"ignore":[],"include":["_destroy"],"copy":[],"observe":[],"mappedProperties":{"accountEnabled":true,"isAppVisible":true,"appListQuery":true,"searchText":true,"top":true,"loadLogo":true,"putCachedLogoUrlOnly":true,"nextLink":true,"usedFirstPartyAppIds":true},"copiedProperties":{}}}'
			#Get managed applications
			$params = @{
				Authentication = $AADAuth;
				Query = "ManagedApplications/List";
				Environment = $Environment;
				ContentType = 'application/json';
				Method = "POST";
				PostData = $post_data;
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			$azure_ad_managed_applications = Get-MonkeyAzurePortalObject @params
		}
		catch {
			Write-Error $_
			Write-Error "Unable to get managed applications from Microsoft Entra ID"
			break
		}
		if ($null -ne $azure_ad_managed_applications) {
			try {
				$param = @{
					ScriptBlock = { Get-MonkeyAADPortalManagedAppProperty -managed_app $_ };
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
				$managed_apps = $azure_ad_managed_applications | Invoke-MonkeyJob @param
			}
			catch {
				Write-Error $_
				Write-Error "Unable to get properties from managed applications from Microsoft Entra ID"
				break
			}
		}
		#Get Permissions for each application
		if ($null -ne $managed_apps) {
			foreach ($managed_app in $managed_apps) {
				if ($null -ne ($managed_app.PSObject.Properties.Item('adminConsentedPerms')) -and $null -ne $managed_app.adminConsentedPerms) {
					foreach ($permission in $managed_app.adminConsentedPerms) {
						#Create new permission object
						$new_app_permission = $managed_app | Select-Object objectId,appId,displayName,appDisplayName
						$new_app_permission | Add-Member NoteProperty -Name resourceName -Value $permission.resourceName
						$new_app_permission | Add-Member NoteProperty -Name resourceAppId -Value $permission.resourceAppId
						$new_app_permission | Add-Member NoteProperty -Name permissionType -Value $permission.PermissionType
						$new_app_permission | Add-Member NoteProperty -Name permissionDisplayName -Value $permission.PermissionDisplayName
						$new_app_permission | Add-Member NoteProperty -Name permissionDescription -Value $permission.PermissionDescription
						$new_app_permission | Add-Member NoteProperty -Name permissionId -Value $permission.PermissionId
						$new_app_permission | Add-Member NoteProperty -Name consentType -Value $permission.ConsentType
						$new_app_permission | Add-Member NoteProperty -Name roleOrScopeClaim -Value $permission.roleOrScopeClaim
						$new_app_permission | Add-Member NoteProperty -Name principalIds -Value $permission.principalIds
						#Add to array
						[void]$managed_apps_permissions.Add($new_app_permission)
					}
				}
				#Get user consented permissions
				if ($null -ne ($managed_app.PSObject.Properties.Item('userConsentedPerms')) -and $null -ne $managed_app.userConsentedPerms) {
					foreach ($permission in $managed_app.userConsentedPerms) {
						#Create new permission object
						$new_app_permission = $managed_app | Select-Object objectId,appId,displayName,appDisplayName
						$new_app_permission | Add-Member NoteProperty -Name resourceName -Value $permission.resourceName
						$new_app_permission | Add-Member NoteProperty -Name resourceAppId -Value $permission.resourceAppId
						$new_app_permission | Add-Member NoteProperty -Name permissionType -Value $permission.PermissionType
						$new_app_permission | Add-Member NoteProperty -Name permissionDisplayName -Value $permission.PermissionDisplayName
						$new_app_permission | Add-Member NoteProperty -Name permissionDescription -Value $permission.PermissionDescription
						$new_app_permission | Add-Member NoteProperty -Name permissionId -Value $permission.PermissionId
						$new_app_permission | Add-Member NoteProperty -Name consentType -Value $permission.ConsentType
						$new_app_permission | Add-Member NoteProperty -Name roleOrScopeClaim -Value $permission.roleOrScopeClaim
						$new_app_permission | Add-Member NoteProperty -Name principalIds -Value $permission.principalIds
						#Add to array
						[void]$managed_apps_permissions.Add($new_app_permission)
					}
				}
			}
		}
		if ([System.Convert]::ToBoolean($aadConf.GetManagedApplicationsByPrincipalId)) {
			#Get managed applications permissions by principalIds
			$principalIds_managed_applications = $managed_apps_permissions | Where-Object { $_.ConsentType -eq "User" } -ErrorAction Ignore
			if ($null -ne $principalIds_managed_applications) {
				try {
					$param = @{
						ScriptBlock = { Get-MonkeyAADPortalManagedAppByPrincipalID -user_managed_app $_ };
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
					$app_by_principalIds = $principalIds_managed_applications | Invoke-MonkeyJob @param
				}
				catch {
					Write-Error $_
					Write-Error "Unable to get Principal Ids"
				}
			}
		}
		else {
			$app_by_principalIds = $null;
		}
	}
	end {
		#Return managed apps properties
		if ($managed_apps) {
			$managed_apps.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.managed_applications.properties')
			[pscustomobject]$obj = @{
				Data = $managed_apps;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_managed_app = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID managed applications",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalManagedAppEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		#Return managed apps permissions properties
		if ($managed_apps_permissions) {
			$managed_apps_permissions.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.managed_applications.permissions')
			[pscustomobject]$obj = @{
				Data = $managed_apps_permissions;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_managed_app_perms = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID managed app permissions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalManagedAppEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		#Return managed apps permissions by principalId
		if ($app_by_principalIds) {
			$app_by_principalIds.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.managed_applications.permissions.byprincipalId')
			[pscustomobject]$obj = @{
				Data = $app_by_principalIds;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_managed_app_perms_byusers = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID managed app user permissions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePortalManagedAppEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










