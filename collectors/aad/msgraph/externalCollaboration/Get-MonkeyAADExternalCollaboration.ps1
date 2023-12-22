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


function Get-MonkeyAADExternalCollaboration {
<#
        .SYNOPSIS
		Collector to get information about external collaboration from Microsoft Entra ID

        .DESCRIPTION
		Collector to get information about external collaboration from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADExternalCollaboration
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
			Id = "aad0019";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADExternalCollaboration";
			ApiType = "MSGraph";
			description = "Collector to get information about external collaboration from Microsoft Entra ID";
			Group = @(
				"EntraID"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"aad_domains"
			);
			dependsOn = @(

			);
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
		$externalCollaboration = $ctAccessPolicy = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID external collaboration settings",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDExternalInfo');
		}
		Write-Information @msg
        #Get External collaboration settings
		$p = @{
			APIVersion = $aadConf.api_version;
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$externalCollaboration = Get-MonkeyMSGraphExternalCollaborationSetting @p
        #Get cross-tenant access policy
		$p = @{
			APIVersion = $aadConf.api_version;
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$ctAccessPolicy = Get-MonkeyMSGraphcrossTenantAccessPolicy @p
	}
	end {
		if ($null -ne $ctAccessPolicy) {
			$ctAccessPolicy.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.CrossTenantAccessPolicy')
			[pscustomobject]$obj = @{
				Data = $ctAccessPolicy;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_cross_tenant_accessPolicy = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID Cross-Tenant access policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('EntraIDCrossTenantEmptyResponse')
			}
			Write-Verbose @msg
		}
        #Return External collaboration settings
        if ($null -ne $externalCollaboration) {
			$externalCollaboration.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.ExternalCollaborationSettings')
			[pscustomobject]$obj = @{
				Data = $externalCollaboration;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_external_collaboration_settings = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID External collaboration settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('EntraIDExternalCollaborationEmptyResponse')
			}
			Write-Verbose @msg
		}
	}
}







