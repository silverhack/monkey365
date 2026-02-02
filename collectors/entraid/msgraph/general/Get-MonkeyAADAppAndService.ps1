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


function Get-MonkeyAADAppAndService {
<#
        .SYNOPSIS
		Collector to get properties and relationships of a adminAppsAndServices object

        .DESCRIPTION
		Collector to get properties and relationships of a adminAppsAndServices object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADAppAndService
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
			Id = "aad0046";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADAppAndService";
			ApiType = "MSGraph";
            objectType = 'EntraAppAndService';
            immutableProperties = @(
                '@odata.context'
            );
			description = "Collector to get properties and relationships of a adminAppsAndServices object";
			Group = @(
				"EntraID"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_app_and_services"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		$settings = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID App And Services",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDInfo');
		}
		Write-Information @msg
		$p = @{
			APIVersion = 'beta';
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$settings = Get-MonkeyMSGraphAppAndService @p
	}
	End {
		If ($null -ne $settings) {
			$settings.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.AppServices')
			[pscustomobject]$obj = @{
				Data = $settings;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_app_and_services = $obj;
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID App And Services",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('EntraIDEmptyResponse')
			}
			Write-Verbose @msg
		}
	}
}









