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


function Get-MonkeyAADSecurityDefault {
<#
        .SYNOPSIS
		Collector to get information about security defaults policy from Microsoft Entra ID

        .DESCRIPTION
		Collector to get information about security defaults policy from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADSecurityDefault
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
			Id = "aad0011";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADSecurityDefault";
			ApiType = "MSGraph";
            objectType = 'SecurityDefault';
            immutableProperties = @(
                'id',
                'displayName'
            );
			description = "Collector to get information about security defaults policy from Microsoft Entra ID";
			Group = @(
				"EntraID"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_security_default"
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
		$sec_defaults = $null
	}
	Process {
        If($null -eq $O365Object.Tenant.licensing.EntraIDP1 -and $O365Object.Tenant.licensing.EntraIDP2){
		    $msg = @{
			    MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID Security Defaults",$O365Object.TenantID);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('EntraIDSecDefaultPolicyInfo');
		    }
		    Write-Information @msg
		    $p = @{
                PolicyType = "SecurityDefault";
			    APIVersion = $aadConf.api_version;
			    InformationAction = $O365Object.InformationAction;
			    Verbose = $O365Object.Verbose;
			    Debug = $O365Object.Debug;
		    }
		    $sec_defaults = Get-MonkeyMSGraphPolicy @p
            If ($null -ne $sec_defaults) {
			    $sec_defaults.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.SecurityDefault')
			    [pscustomobject]$obj = @{
				    Data = $sec_defaults;
				    Metadata = $monkey_metadata;
			    }
			    $returnData.aad_security_default = $obj;
		    }
        }
	}
}