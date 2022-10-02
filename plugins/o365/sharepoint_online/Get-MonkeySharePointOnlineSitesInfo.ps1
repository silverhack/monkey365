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


function Get-MonkeySharePointOnlineSitesInfo {
<#
        .SYNOPSIS
		Plugin to get information about O365 Sharepoint Online sites

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online sites

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineSitesInfo
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
			Id = "sps0007";
			Provider = "Microsoft365";
			Title = "Plugin to get information about Sharepoint Online sites";
			Group = @("SharepointOnline");
			ServiceName = "SharePoint Online Sites";
			PluginName = "Get-MonkeySharePointOnlineSitesInfo";
			Docs = "https://silverhack.github.io/monkey365/"
		}
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online Sites",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('SPSSitesInfo');
		}
		Write-Information @msg
		#Get all webs for user
		$all_sites = Get-MonkeySPSSitesForUser
	}
	end {
		if ($all_sites) {
			$all_sites.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Sites')
			[pscustomobject]$obj = @{
				Data = $all_sites;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_sites = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online Sites",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SPSSitesEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
