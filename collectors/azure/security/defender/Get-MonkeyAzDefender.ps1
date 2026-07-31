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


function Get-MonkeyAzDefender {
<#
        .SYNOPSIS
		Collector to get defender metadata (pricing, assessments, policy assignments, etc..) from Azure

        .DESCRIPTION
		Collector to get defender metadata (pricing, assessments, policy assignments, etc..) from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzDefender
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
			Id = "az00072";
			Provider = "Azure";
			Resource = "Subscription";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzDefender";
			ApiType = "resourceManagement";
			description = "Collector to get defender metadata (pricing, assessments, policy assignments, etc..) from Azure";
			Group = @(
				"Subscription"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_defender"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
	}
	Process{
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Defender",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureDefenderInfo');
		}
		Write-Information @msg
        #Get Defender metadata
        $p = @{
            InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
            Debug = $O365Object.debug;
        }
        $defender = Get-MonkeyAzDefenderInfo @p
        If($null -ne $defender){
            $defender.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Defender')
			[pscustomobject]$obj = @{
				Data = $defender;
				Metadata = $monkey_metadata;
			}
			$returnData.az_defender = $obj
        }
        Else{
            $msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Defender",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzurePricingEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg            
        }
	}
}