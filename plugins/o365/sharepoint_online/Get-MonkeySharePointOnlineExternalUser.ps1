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


function Get-MonkeySharePointOnlineExternalUser {
<#
        .SYNOPSIS
		Plugin to get information about SPS external users

        .DESCRIPTION
		Plugin to get information about SPS external users

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineExternalUser
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
			Id = "sps0002";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeySharePointOnlineExternalUser";
			ApiType = $null;
			Title = "Plugin to get information about SPS external users";
			Group = @("SharePointOnline");
			Tags = @{
			    "enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
        if($null -eq $O365Object.spoWebs){
            break
        }
        #set generic list
        $all_external_users = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
	}
	Process {
        $msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"SharePoint Online external users",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('SPSExternalUsersInfo');
		}
		Write-Information @msg
        foreach($web in $O365Object.spoWebs){
            $p = @{
                Web = $web;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $ext_users = Get-MonkeyCSOMExternalUser @p
            if($ext_users){
                #Add to list
                foreach($ext_user in $ext_users){
                    [void]$all_external_users.Add($ext_user)
                }
            }
        }
	}
	End {
		if ($all_external_users) {
			$all_external_users.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Tenant.Externalusers')
			[pscustomobject]$obj = @{
				Data = $all_external_users;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_external_users = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online External Users",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.Verbose;
				Tags = @('SPSExternalUsersEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}




