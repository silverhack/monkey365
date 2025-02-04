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


function Get-MonkeyFormsUserInfo {
<#
        .SYNOPSIS
		Collector to get information about current user in Microsoft Forms

        .DESCRIPTION
		Collector to get information about current user in Microsoft Forms

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyFormsUserInfo
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
		$forms_user_info = $null
		#Collector metadata
		$monkey_metadata = @{
			Id = "forms02";
			Provider = "Microsoft365";
			Resource = "MicrosoftForms";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyFormsUserInfo";
			ApiType = $null;
			description = "Collector to get information about current user in Microsoft Forms";
			Group = @(
				"AdminPortal"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_forms_current_user_info"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Forms. Current user info",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('FormsCurrentUserInfo');
		}
		if ($null -ne $O365Object.auth_tokens.Forms) {
			$authHeader = @{
				Authorization = $O365Object.auth_tokens.Forms.CreateAuthorizationHeader()
			}
			$url = ("{0}/formapi/api/userInfo" -f $O365Object.Environment.Forms)
			$params = @{
				url = $url;
				Method = 'Get';
				ContentType = 'application/json';
				Headers = $authHeader;
			}
			#call user info
			$forms_user_info = Invoke-MonkeyWebRequest @params
		}
	}
	end {
		if ($forms_user_info) {
			$forms_user_info.PSObject.TypeNames.Insert(0,'Monkey365.Forms.UserInfo')
			[pscustomobject]$obj = @{
				Data = $forms_user_info;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_forms_current_user_info = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft 365 Forms. Current user info",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('FormsCurrentUserEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










