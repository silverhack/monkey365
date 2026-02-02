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


function Get-MonkeyRestEXOUsersMailbox {
<#
        .SYNOPSIS
		Collector to get information about mailboxes in Exchange Online

        .DESCRIPTION
		Collector to get information about mailboxes in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyRestEXOUsersMailbox
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
			Id = "exo0030";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyRestEXOUsersMailbox";
			ApiType = "ExoApi";
			description = "Collector to get information about mailboxes in Exchange Online";
			Group = @(
				"ExchangeOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_exo_mailboxes";
				"o365_exo_mailbox_forwarding";
				"o365_exo_mailbox_permissions"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		$mailbox_permissions = $null
		#Getting environment
		$Environment = $O365Object.Environment
		#Get EXO authentication
		$exo_auth = $O365Object.auth_tokens.ExchangeOnline
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Exchange Online Mailboxes",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('ExoMailboxesInfo');
		}
		Write-Information @msg
		#Get Mailboxes
		$param = @{
			Authentication = $exo_auth;
			Environment = $Environment;
			ResponseFormat = 'clixml';
			Command = 'Get-Mailbox -ResultSize unlimited';
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$mailBoxes = Get-PSExoAdminApiObject @param
		if ($mailboxes) {
			#Get mailbox Forwarding
			$forwarding_mailboxes = $mailboxes | Select-Object @{Name='userPrincipalName';Expression={$_.UserPrincipalName}},@{Name='identity';Expression={$_.Identity}}, @{Name='ExchangeObjectId';Expression={$_.ExchangeObjectId.Guid}}, @{Name='ForwardingSmtpAddress';Expression={$_.ForwardingSmtpAddress}},@{Name='DeliverToMailboxAndForward';Expression={$_.DeliverToMailboxAndForward}}
			#Getting mailbox permissions
			$p = @{
				ScriptBlock = { Get-PSExoMailBoxPermission -MailBox $_ };
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.MaxQueue;
				BatchSleep = $O365Object.BatchSleep;
				BatchSize = $O365Object.BatchSize;
			}
			#Get objects
			$mailbox_permissions = $mailboxes | Invoke-MonkeyJob @p
		}
	}
	end {
		if ($mailboxes) {
			$mailboxes.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.Mailboxes')
			[pscustomobject]$obj = @{
				Data = $mailboxes;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_mailboxes = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online mailboxes",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoMailboxesEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		if ($forwarding_mailboxes) {
			$forwarding_mailboxes.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.ForwardingMailboxes')
			[pscustomobject]$obj = @{
				Data = $forwarding_mailboxes;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_mailbox_forwarding = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online mailbox forwarding",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoMailboxesEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		if ($mailbox_permissions) {
			$mailbox_permissions.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.MailboxPermissions')
			[pscustomobject]$obj = @{
				Data = $mailbox_permissions;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_mailbox_permissions = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online mailbox permissions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoMailboxesEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









