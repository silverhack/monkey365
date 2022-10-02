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


function Get-MonkeyADPasswordPolicy {
<#
        .SYNOPSIS
		Plugin to get password policy from Azure AD

        .DESCRIPTION
		Plugin to get password policy from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADPasswordPolicy
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
		$Environment = $O365Object.Environment
		#Plugin metadata
		$monkey_metadata = @{
			Id = "aad0021";
			Provider = "AzureAD";
			Title = "Plugin to get password policy from Azure AD";
			Group = @("AzureADPortal");
			ServiceName = "Azure AD Password Policy";
			PluginName = "Get-MonkeyADPasswordPolicy";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Azure Active Directory Auth
		$AADAuth = $O365Object.auth_tokens.AzurePortal
		#Query
		$params = @{
			Authentication = $AADAuth;
			Query = $null;
			Environment = $Environment;
			ContentType = 'application/json';
			Method = "GET";
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD password policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePortalAuthPolicy');
		}
		Write-Information @msg
		#Get password policy
		$params.Query = "AuthenticationMethods/PasswordPolicy"
		$ad_password_policy = Get-MonkeyAzurePortalObject @params
		#Get password policy from Graph (if configured)
		$params.Query = "MsGraph/beta/settings"
		$ad_password_policy_template = Get-MonkeyAzurePortalObject @params
		$password_policy_template = $ad_password_policy_template | Where-Object { $_.displayName -eq "Password Rule Settings" }
		if ($password_policy_template) {
			#Create array
			$ad_password_template_policy = @()
			foreach ($naming_policy in $password_policy_template) {
				$NewNamingPolicy = New-Object -TypeName PSCustomObject
				$NewNamingPolicy | Add-Member -Type NoteProperty -Name Id -Value $naming_policy.id
				$NewNamingPolicy | Add-Member -Type NoteProperty -Name displayName -Value $naming_policy.displayName
				$NewNamingPolicy | Add-Member -Type NoteProperty -Name templateId -Value $naming_policy.templateId
				foreach ($element in $naming_policy.values.GetEnumerator()) {
					try {
						$NewNamingPolicy | Add-Member -Type NoteProperty -Name $element.Name -Value $element.value
					}
					catch {
						$msg = @{
							MessageData = $_;
							callStack = (Get-PSCallStack | Select-Object -First 1);
							logLevel = 'error';
							InformationAction = $InformationAction;
							Tags = @('AzurePortalPasswordPolicy');
						}
						Write-Debug @msg
						$msg = @{
							MessageData = "Unable to get property of naming policy";
							callStack = (Get-PSCallStack | Select-Object -First 1);
							logLevel = 'error';
							InformationAction = $InformationAction;
							Tags = @('AzurePortalPasswordPolicy');
						}
						Write-Verbose @msg
					}
					continue;
				}
				#Add to array
				$ad_password_template_policy += $NewNamingPolicy;
			}
		}
	}
	end {
		if ($ad_password_policy) {
			$ad_password_policy.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.PasswordPolicy')
			[pscustomobject]$obj = @{
				Data = $ad_password_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_password_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD password policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalTemplatePolicyEmptyResponse');
			}
			Write-Warning @msg
		}
		#Check if password policy template
		if ($ad_password_template_policy) {
			$ad_password_template_policy.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.PasswordPolicyTemplate')
			[pscustomobject]$obj = @{
				Data = $ad_password_template_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_password_template_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD password template policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePortalTemplatePolicyEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
