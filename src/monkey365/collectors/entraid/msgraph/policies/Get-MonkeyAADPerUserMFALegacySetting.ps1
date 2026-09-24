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


function Get-MonkeyAADPerUserMFALegacySetting {
<#
        .SYNOPSIS
		Collector to get information about per-user legacy MFA settings from Microsoft Entra ID

        .DESCRIPTION
		Collector to get information about per-user legacy MFA settings from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADPerUserMFALegacySetting
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	Begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "aad0012";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADPerUserMFALegacySetting";
			ApiType = "MSGraph";
            objectType = 'SecurityDefault';
            immutableProperties = @(
                '@odata.context'
            );
			description = "Collector to get information about per-user legacy MFA settings from Microsoft Entra ID";
			Group = @(
				"EntraID"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_mfa_legacy_settings"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		$mfa_Settings = $null
	}
	Process {
        If($null -eq $O365Object.Tenant.licensing.EntraIDP1 -and $O365Object.Tenant.licensing.EntraIDP2){
		    $msg = @{
			    MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID Legacy MFA Settings",$O365Object.TenantID);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('EntraIDMFALegacyPolicyInfo');
		    }
		    Write-Information @msg
		    $p = @{
                PolicyType = "mfaServicePolicy";
			    APIVersion = 'beta';
			    InformationAction = $O365Object.InformationAction;
			    Verbose = $O365Object.Verbose;
			    Debug = $O365Object.Debug;
		    }
		    $mfa_Settings = Get-MonkeyMSGraphPolicy @p
            If ($null -ne $mfa_Settings) {
                #Add GUID and Name due to legacy output
                $mfa_Settings | Add-Member -MemberType NoteProperty -Name id -Value 5be848a5-389a-43e2-8cc0-9dd87bb9b33c -Force
                $mfa_Settings | Add-Member -MemberType NoteProperty -Name name -Value legacyMfaServicePolicy -Force
			    $mfa_Settings.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.legacy.MFA.settings')
			    [pscustomobject]$obj = @{
				    Data = $mfa_Settings;
				    Metadata = $monkey_metadata;
			    }
			    $returnData.aad_mfa_legacy_settings = $obj;
		    }
        }
	}
}