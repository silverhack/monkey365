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


function Get-MonkeyAADSecureScoreControlProfile {
<#
        .SYNOPSIS
		Plugin to get information about Azure AD secure score control profile

        .DESCRIPTION
		Plugin to get information about Azure AD secure score control profile

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADSecureScoreControlProfile
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
			Id = "aad0051";
			Provider = "AzureAD";
			Resource = "AzureAD";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAADSecureScoreControlProfile";
			ApiType = "MSGraph";
			Title = "Plugin to get information about Azure AD secure score control profile";
			Group = @("AzureAD");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Config
        try{
            $aadConf = $O365Object.internal_config.azuread.provider.msgraph
        }
        catch{
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
		$ss_control_profile = $null
	}
	process {
        $msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure AD secure score control profile",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureADSecureScoreProfileInfo');
		}
		Write-Information @msg
		$p = @{
			APIVersion = $aadConf.api_version;
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$ss_control_profile = Get-MonkeyMSGraphSecureScoreControlProfile @p
	}
	end {
		if ($null -ne $ss_control_profile) {
			$ss_control_profile.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.SecureScoreControlProfile')
			[pscustomobject]$obj = @{
				Data = $ss_control_profile;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_conditional_access_policy = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure AD secure score control profile",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('AzureADSecureScoreProfileEmptyResponse')
			}
			Write-Verbose @msg
		}
	}
}




