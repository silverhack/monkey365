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

Function Get-MonkeySPOSiteCollectionMember {
    <#
        .SYNOPSIS
		Get Site collection members from Sharepoint Online

        .DESCRIPTION
		Get Site collection members from Sharepoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPOSiteCollectionMember
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
                MessageData = ("Getting Site membership from {0}" -f $title);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('SPOSiteMemberInfo');
            }
            Write-Information @msg
            $p = @{
                Authentication = $O365Object.auth_tokens.SharePointAdminOnline;
                ObjectPath = 'SPO.Tenant';
                ObjectType = 'sites';
                Method = "POST";
                SiteId = $sid;
                GetSiteUserGroups = $true;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $siteMembers = Invoke-MonkeySPOAdminRestQuery @p
            if($null -ne $siteMembers){
                if($PSBoundParameters.ContainsKey('ExpandIdentity') -and $PSBoundParameters['ExpandIdentity'].IsPresent){
                    $siteOwners = [System.Collections.Generic.List[System.Object]]::new()
                    $siteMembersArr = [System.Collections.Generic.List[System.Object]]::new()
                    $siteVisitors = [System.Collections.Generic.List[System.Object]]::new()
                    $Identities = $siteMembers.Value
                    #Get site owners
                    if($Identities.Count -gt 0){
                        $msg = @{
                            MessageData = ("Getting Site owners from {0}" -f $sid);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'info';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('SPOSiteMemberInfo');
                        }
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
                        $owners = $Identities[0].userGroup.GetEnumerator() | Invoke-MonkeyJob @p
                        if($null -ne $owners -and @($owners).Count -gt 0){
                            foreach($m in $owners){
                                [void]$siteOwners.Add($m);
                            }
                        }
                    }
                    #Get site members
                    if($Identities.Count -gt 1){
                        $msg = @{
                            MessageData = ("Getting Site members from {0}" -f $sid);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'info';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('SPOSiteMemberInfo');
                        }
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
                        $members = $Identities[1].userGroup.GetEnumerator() | Invoke-MonkeyJob @p
                        if($null -ne $members -and @($members).Count -gt 0){
                            foreach($m in $members){
                                [void]$siteMembersArr.Add($m);
                            }
                        }
                    }
                    #Get site visitors
                    if($Identities.Count -gt 2){
                        $msg = @{
                            MessageData = ("Getting Site visitors from {0}" -f $sid);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'info';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('SPOSiteMemberInfo');
                        }
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
                        $visitors = $Identities[1].userGroup.GetEnumerator() | Invoke-MonkeyJob @p
                        if($null -ne $visitors -and @($visitors).Count -gt 0){
                            foreach($m in $visitors){
                                [void]$siteVisitors.Add($m);
                            }
                        }
                    }
                    $psObject = [psObject]@{
                        siteOwners = $siteOwners;
                        siteMembers = $siteMembers;
                        siteVisitors = $siteVisitors;
                    }
                    Write-Output $psObject -NoEnumerate
                }
                else{
                    $siteMembers.Value
                }
            }
        }
    }
}
