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


function Get-MonkeySharePointOnlineSitePermissionsInfo {
<#
        .SYNOPSIS
		Plugin to get information about O365 Sharepoint Online site permissions

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online site permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineSitePermissionsInfo
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
		#Set array
		#Plugin metadata
		$monkey_metadata = @{
			Id = "sps0006";
			Provider = "Microsoft365";
			Title = "Plugin to get information about Sharepoint Online site permissions";
			Group = @("SharePointOnline");
			ServiceName = "SharePoint Online Site permissions";
			PluginName = "Get-MonkeySharePointOnlineSitePermissionsInfo";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		$all_perms = @()
		<#
        $vars = @{
            O365Object = $O365Object;
            WriteLog = $WriteLog;
            Verbosity = $Verbosity;
            InformationAction = $InformationAction;
        }
        #>
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online site permissions",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('SPSSitePermsInfo');
		}
		Write-Information @msg
		#Get all webs for user
		$allowed_sites = Get-MonkeySPSWebsForUser
		#Getting external users for each site
		<#
        $param = @{
            ScriptBlock = {Get-MonkeyPSWebPermission -Web $_};
            ImportCommands = $O365Object.LibUtils;
            ImportVariables = $vars;
            ImportModules = $O365Object.runspaces_modules;
            StartUpScripts = $O365Object.runspace_init;
            StartUpScripts = $O365Object.runspace_init;
            ThrowOnRunspaceOpenError = $true;
            Debug = $O365Object.VerboseOptions.Debug;
            Verbose = $O365Object.VerboseOptions.Verbose;
            Throttle = $O365Object.nestedRunspaceMaxThreads;
            MaxQueue = $O365Object.MaxQueue;
            BatchSleep = $O365Object.BatchSleep;
            BatchSize = $O365Object.BatchSize;
        }
        $allowed_sites | Invoke-MonkeyJob @param | ForEach-Object {
            if($_){
                $all_perms+=$_
            }
        }
        #>
		foreach ($site in $allowed_sites) {
			$all_perms += Get-MonkeyPSWebPermission -Web $site
		}
	}
	end {
		if ($all_perms) {
			$all_perms.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Permissions')
			[pscustomobject]$obj = @{
				Data = $all_perms;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_permissions = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online site permissions",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SPSSitePermissionsEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
