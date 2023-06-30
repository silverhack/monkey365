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
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeySharePointOnlineSitesInfo";
			ApiType = "CSOM";
			Title = "Plugin to get information about Sharepoint Online sites";
			Group = @("SharePointOnline");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
        if($null -eq $O365Object.spoWebs){
            break
        }
        #Get config
        try{
            $scanSites = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.ScanSites)
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
            #Set scanSites to false
            $scanSites = $false
        }
        #set generic list
        $all_sites = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online Sites",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('SPSSitesInfo');
		}
		Write-Information @msg
        if($null -ne $O365Object.spoWebs){
            $p = @{
                Webs = $O365Object.spoWebs;
                ScanSites = $scanSites;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $sites = Get-MonkeyCSOMSitesForUser @p
        }
        else{
            $p = @{
                ScanSites = $scanSites;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $sites = Get-MonkeyCSOMSitesForUser @p
        }
		if($sites){
            foreach($site in @($sites)){
                #Check if exists
                $match = $all_sites | Where-Object {$_.Url -eq $site.Url}
                if(-NOT $match){
                    #Add to list
                    [void]$all_sites.Add($site)
                }
            }
        }
	}
	End {
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
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.Verbose;
				Tags = @('SPSSitesEmptyResponse');
			}
			Write-Verbose @msg
		}
	}
}




