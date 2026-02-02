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
# See the License for the specIfic language governing permissions and
# limitations under the License.


function Get-MonkeyFabricWorkspaceInfo {
<#
        .SYNOPSIS
		Collector to get information about workspaces, datasets, etc.. from Microsoft PowerBI

        .DESCRIPTION
		Collector to get information about workspaces, datasets, etc.. from Microsoft PowerBI

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyFabricWorkspaceInfo
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
			Id = "fabric003";
			Provider = "Microsoft365";
			Resource = "MicrosoftFabric";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyFabricWorkspaceInfo";
			ApiType = $null;
            objectType = 'FabricWorkspaceInfo';
            immutableProperties = @(
                'id',
                'name',
                'type'
            );
			description = "Collector to get information about workspaces, datasets, etc.. from Microsoft PowerBI";
			Group = @(
				"MicrosoftFabric"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"m365_fabric_workspace_info"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
        #Set null
		$workspaceInfo = $null
	}
	Process {
        $msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Microsoft Fabric: Workspace Information",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('FabricWorkspaceInfo');
		}
		Write-Information @msg
		$p = @{
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
		$workspaceInfo = Invoke-MonkeyPowerBiScan @p
	}
	End {
		If ($workspaceInfo) {
			$workspaceInfo.PSObject.TypeNames.Insert(0,'Monkey365.Fabric.WorkspaceInfo')
			[pscustomobject]$obj = @{
				Data = $workspaceInfo;
				Metadata = $monkey_metadata;
			}
			$returnData.m365_fabric_workspace_info = $obj
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Fabric: Workspace Information",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('FabricWorkspaceInfoEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}