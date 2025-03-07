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


function Get-MonkeySharePointOnlineWeb {
<#
        .SYNOPSIS
		Collector to get information about O365 Sharepoint Online site web

        .DESCRIPTION
		Collector to get information about O365 Sharepoint Online site web

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineWeb
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
			Id = "sps0012";
			Provider = "Microsoft365";
			Resource = "SharePointOnline";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeySharePointOnlineWeb";
			ApiType = "CSOM";
			description = "Collector to get information about O365 Sharepoint Online site web";
			Group = @(
				"SharePointOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_spo_webs"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get config
		try {
			#Splat params
			$pWeb = @{
				Authentication = $O365Object.auth_tokens.SharePointOnline;
				Recurse = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Subsites.Recursive);
				Limit = $O365Object.internal_config.o365.SharePointOnline.Subsites.Depth;
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
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
			#Splat params
			$pWeb = @{
				Authentication = $O365Object.auth_tokens.SharePointOnline
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
		}
        $abort = $true
	}
	Process {
        If($null -ne $O365Object.spoSites){
            $abort = $false;
		    $msg = @{
			    MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Sharepoint Online webs",$O365Object.TenantID);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('SPSWebsInfo');
		    }
		    Write-Information @msg
		    #Get all webs for user
		    $all_webs = @($O365Object.spoSites).ForEach({ $_.url | Get-MonkeyCSOMWeb @pWeb })
        }
	}
	End {
        If($abort -eq $false){
		    If ($all_webs) {
			    $all_webs.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Webs')
			    [pscustomobject]$obj = @{
				    Data = $all_webs;
				    Metadata = $monkey_metadata;
			    }
			    $returnData.o365_spo_webs = $obj
		    }
		    Else {
			    $msg = @{
				    MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online webs",$O365Object.TenantID);
				    callStack = (Get-PSCallStack | Select-Object -First 1);
				    logLevel = "verbose";
				    InformationAction = $O365Object.InformationAction;
				    Tags = @('SPSWebsEmptyResponse');
				    Verbose = $O365Object.Verbose;
			    }
			    Write-Verbose @msg
		    }
        }
	}
}










