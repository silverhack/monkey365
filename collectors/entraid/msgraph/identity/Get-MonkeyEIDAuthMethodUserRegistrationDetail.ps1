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


function Get-MonkeyEIDAuthMethodUserRegistrationDetail {
<#
        .SYNOPSIS
		Collector to get a list of the authentication methods registered for all users

        .DESCRIPTION
		Collector to get a list of the authentication methods registered for all users

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEIDAuthMethodUserRegistrationDetail
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
			Id = "aad0010";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyEIDAuthMethodUserRegistrationDetail";
			ApiType = "MSGraph";
            objectType = 'EntraIdAuthMethodUserRegistrationDetail';
            immutableProperties = @(
                'id'
            );
			description = "Collector to get a list of the authentication methods registered for all users";
			Group = @(
				"EntraID"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_auth_method_user_registration_detail"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
        #Get Config
		try {
			$aadConf = $O365Object.internal_config.entraId.Provider.msgraph
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
		$user_registration_detail = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID User Authentication Method Registration Detail",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDAuthMethodRegistrationInfo');
		}
		Write-Information @msg
		$p = @{
			APIVersion = $aadConf.api_version;
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$user_registration_detail = Get-MonkeyMSGraphAuthMethodUserRegistrationDetail @p
	}
	end {
		if ($null -ne $user_registration_detail) {
			$user_registration_detail.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.Auth.Method.User.Registration.Detail')
			[pscustomobject]$obj = @{
				Data = $user_registration_detail;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_auth_method_user_registration_detail = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID User Authentication Method Registration Detail",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('EntraIDAuthMethodRegistrationEmptyResponse')
			}
			Write-Verbose @msg
		}
	}
}









