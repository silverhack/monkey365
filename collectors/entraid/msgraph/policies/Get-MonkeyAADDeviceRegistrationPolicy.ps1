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


function Get-MonkeyAADDeviceRegistrationPolicy {
<#
        .SYNOPSIS
		Collector to get information about device registration policy from Microsoft Entra ID

        .DESCRIPTION
		Collector to get information about device registration policy from Microsoft Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADDeviceRegistrationPolicy
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
			Id = "aad0043";
			Provider = "EntraID";
			Resource = "EntraID";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADDeviceRegistrationPolicy";
			ApiType = "MSGraph";
            objectType = 'EntraDeviceRegistrationPolicy';
            immutableProperties = @(
                'id'
            );
			description = "Collector to get information about device registration policy from Microsoft Entra ID";
			Group = @(
				"EntraID"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"aad_device_settings"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		$device_policy = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Entra ID device settings",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('EntraIDAuthPolicyInfo');
		}
		Write-Information @msg
		$p = @{
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$device_policy = Get-MonkeyMSGraphDeviceRegistrationPolicy @p
	}
	end {
		if ($null -ne $device_policy) {
			$device_policy.PSObject.TypeNames.Insert(0,'Monkey365.EntraID.DeviceSettings')
			[pscustomobject]$obj = @{
				Data = $device_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.aad_device_settings = $obj;
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Entra ID device settings",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Tags = @('EntraIDAuthPolicyEmptyResponse')
			}
			Write-Verbose @msg
		}
	}
}









