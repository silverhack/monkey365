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

Function Get-MonkeySPOSiteCollectionAdministrator {
    <#
        .SYNOPSIS
		Get Site collection administrators from Sharepoint Online

        .DESCRIPTION
		Get Site collection administrators from Sharepoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPOSiteCollectionAdministrator
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ParameterSetName = 'SiteId', ValueFromPipeline = $True)]
        [String]$SiteId,

        [Parameter(Mandatory=$true, ParameterSetName = 'Site', ValueFromPipeline = $True)]
        [Object]$Site,

        [Parameter(Mandatory=$false)]
        [Switch]$ExpandIdentity
    )
    Begin{
        $spoAuth = $O365Object.auth_tokens.SharePointAdminOnline;
        $sid = $title = $null
    }
    Process{
        try{
            if($PSCmdlet.ParameterSetName -eq 'Site'){
                $sid = $PSBoundParameters['Site'].SiteId.Split('()')[1]
                $title = $PSBoundParameters['Site'].Title
            }
            else{
                $sid = $PSBoundParameters['SiteId']
                $title = $PSBoundParameters['SiteId']
            }
        }
        catch{
            Write-Error $_
        }
    }
    End{
        if($sid){
            $msg = @{
                MessageData = ("Getting Site Administrators from {0}" -f $title);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('SPOSiteAdminInfo');
            }
            Write-Information @msg
            $p = @{
                Authentication = $spoAuth;
                ObjectPath = 'SPO.Tenant';
                ObjectType = 'GetSiteAdministrators';
                Method = "POST";
                SiteId = $sid;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $siteAdmins = Invoke-MonkeySPOAdminRestQuery @p
            if($null -ne $siteAdmins){
                if($PSBoundParameters.ContainsKey('ExpandIdentity') -and $PSBoundParameters['ExpandIdentity'].IsPresent){
                    $p = @{
	                    ScriptBlock = { Resolve-MonkeySPORestIdentity -InputObject $_};
	                    Runspacepool = $O365Object.monkey_runspacePool;
	                    ReuseRunspacePool = $true;
	                    Debug = $O365Object.VerboseOptions.Debug;
	                    Verbose = $O365Object.VerboseOptions.Verbose;
	                    MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	                    BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	                    BatchSize = $O365Object.nestedRunspaces.BatchSize;
                    }
                    $siteAdmins.Value | Invoke-MonkeyJob @p
                }
                else{
                    $siteAdmins.Value
                }
            }
        }
    }
}
