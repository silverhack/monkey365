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


function Get-MonkeyAzSecurityContact {
<#
        .SYNOPSIS
		Azure plugin to get Security Contacts

        .DESCRIPTION
		Azure plugin to get Security Contacts

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSecurityContact
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
			Id = "az00035";
			Provider = "Azure";
			Resource = "Subscription";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAzSecurityContact";
			ApiType = "resourceManagement";
			Title = "Plugin to get Security Contacts fron Azure";
			Group = @("Subscription");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure RM Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get config
		$azureContactConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureContacts" } | Select-Object -ExpandProperty resource
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Security Contacts",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureSecContactInfo');
		}
		Write-Information @msg
		#List All Security Contacts
		$params = @{
			Authentication = $rm_auth;
			Provider = $azureContactConfig.Provider;
			ObjectType = "securityContacts";
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
			APIVersion = $azureContactConfig.api_version;
		}
		$securityContacts = Get-MonkeyRMObject @params
		#Create array
		$allsecurityContacts = @()
		foreach ($account in $securityContacts) {
			$email_notification_dict = [ordered]@{
				Id = $account.Id;
				location = $account.Id;
				Name = $account.Name;
				Properties = $account.Properties;
				email = $account.Properties.emails;
				phone = $account.Properties.phone;
				alertNotifications = $account.Properties.alertNotifications;
				notificationsByRole = $account.Properties.notificationsByRole;
				rawObject = $account;
			}
			$email_notification_obj = New-Object -TypeName PSCustomObject -Property $email_notification_dict
			#Decorate object
			$email_notification_obj.PSObject.TypeNames.Insert(0,'Monkey365.Azure.securityContact')
			#Add to array
			$allsecurityContacts += $email_notification_obj
		}
	}
	end {
		if ($allsecurityContacts) {
			$allsecurityContacts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.securityContacts')
			[pscustomobject]$obj = @{
				Data = $allsecurityContacts;
				Metadata = $monkey_metadata;
			}
			$returnData.az_security_contacts = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Security Contacts",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureKeySecContactEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




