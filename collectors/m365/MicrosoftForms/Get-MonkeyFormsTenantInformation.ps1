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


function Get-MonkeyFormsTenantInformation {
<#
        .SYNOPSIS
		Collector to get information about Microsoft Forms tenant settings

        .DESCRIPTION
		Collector to get information about Microsoft Forms tenant settings

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyFormsTenantInformation
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
		$forms_tenant_settings = $null;
		#Collector metadata
		$monkey_metadata = @{
			Id = "forms01";
			Provider = "Microsoft365";
			Resource = "MicrosoftForms";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyFormsTenantInformation";
			ApiType = $null;
			description = "Collector to get information about Microsoft Forms tenant settings";
			Group = @(
				"Microsoft365"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"o365_forms_tenant_settings"
			);
			dependsOn = @(

			);
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Forms. Tenant Settings",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('FormsTenantInfo');
		}
		if ($null -ne $O365Object.auth_tokens.Forms) {
			$authHeader = @{
				Authorization = $O365Object.auth_tokens.Forms.CreateAuthorizationHeader()
			}
			$url = ("{0}/formapi/api/GetFormsTenantSettings" -f $O365Object.Environment.Forms)
			$params = @{
				url = $url;
				Method = 'Get';
				ContentType = 'application/json';
				Headers = $authHeader;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.Verbose;
			}
			#call tenant settings
			$forms_tenant_settings = Invoke-MonkeyWebRequest @params
		}
		else {
			$msg = @{
				MessageData = ("Unable to get tenant's information from Microsoft Forms");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $O365Object.InformationAction;;
				Tags = @('FormsTenantInfoWarning');
			}
			Write-Warning @msg
		}
	}
	end {
		if ($null -ne $forms_tenant_settings) {
			$forms_tenant_settings.PSObject.TypeNames.Insert(0,'Monkey365.Forms.TenantSettings')
			[pscustomobject]$obj = @{
				Data = $forms_tenant_settings;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_forms_tenant_settings = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft 365 Forms. Tenant settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('FormsTenantInfoEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







