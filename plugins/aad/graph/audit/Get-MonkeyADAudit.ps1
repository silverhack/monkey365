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


function Get-MonkeyADAudit {
<#
        .SYNOPSIS
		Plugin extract audit logs from Azure AD

        .DESCRIPTION
		Plugin extract audit logs from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADAudit
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
			Id = "aad0002";
			Provider = "AzureAD";
			Title = "Plugin to extract audit logs from Azure AD";
			Group = @("AzureAD");
			ServiceName = "Azure AD Audit";
			PluginName = "Get-MonkeyADAudit";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.Graph
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"audit",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureGraphAuditLog');
		}
		Write-Information @msg
		try {
			$DaysAgo = "{0:s}" -f (Get-Date).AddDays($AADConfig.AuditLogDaysAgo) + "Z"
		}
		catch {
			$DaysAgo = -15
		}
		$Query = '&$filter=activityDate gt {0}' -f $DaysAgo
		#Get audit log
		$params = @{
			Authentication = $AADAuth;
			ObjectType = 'activities/audit';
			Query = $Query
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			APIVersion = "beta";
		}
		#Get Audit Logs from Azure AAD
		$all_events = Get-MonkeyGraphObject @params
		$formatted_events = @()
		if ($all_events) {
			$msg = @{
				MessageData = ($message.MonkeyResponseCountMessage -f $all_events.Count);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('AzureGraphAuditLogCount');
			}
			Write-Information @msg
			#Iterate over all events
			foreach ($entry in $all_events) {
				$entry.actor = $entry.actor.userPrincipalName
				$entry | Add-Member -Type NoteProperty -Name targetResourceType -Value $entry.targets.targetResourceType
				$entry | Add-Member -Type NoteProperty -Name targetobjectId -Value $entry.targets.objectId
				$entry | Add-Member -Type NoteProperty -Name targetName -Value $entry.targets.Name
				$entry | Add-Member -Type NoteProperty -Name targetUserPrincipalName -Value $entry.targets.userPrincipalName
				$Changes = $entry.targets.modifiedProperties
				$entry | Add-Member -Type NoteProperty -Name ChangeAttribute -Value (@($Changes.Name) -join ',')
				$entry | Add-Member -Type NoteProperty -Name OldValue -Value (@($Changes.oldvalue) -join ',')
				$entry | Add-Member -Type NoteProperty -Name NewValue -Value (@($Changes.newvalue) -join ',')
				$formatted_events += $entry
			}
		}
	}
	end {
		if ($formatted_events) {
			$formatted_events = $formatted_events | Select-Object $AADConfig.AuditLogFilter
			$formatted_events.PSObject.TypeNames.Insert(0,'Monkey365.AzureAAD.AuditLogs')
			[pscustomobject]$obj = @{
				Data = $formatted_events;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_audit_logs = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Audit Log",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzureGraphUsersEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
