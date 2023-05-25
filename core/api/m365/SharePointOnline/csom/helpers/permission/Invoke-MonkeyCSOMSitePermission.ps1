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


Function Invoke-MonkeyCSOMSitePermission{
    <#
        .SYNOPSIS
		Get Sharepoint Online site permissions

        .DESCRIPTION
		Get Sharepoint Online site permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyCSOMSitePermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $true, HelpMessage="SharePoint Web Object")]
        [Object]$Web,

        [Parameter(Mandatory= $false, HelpMessage="Scan files")]
        [Switch]$ScanFiles,

        [Parameter(Mandatory= $false, HelpMessage="Scan folders")]
        [Switch]$ScanFolders,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions for site")]
        [Switch]$SiteInheritedPermission,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions for lists")]
        [Switch]$ListInheritedPermission,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions for folders")]
        [Switch]$FolderInheritedPermission,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions for files")]
        [Switch]$FileInheritedPermission
    )
    Begin{
        #Set generic dict
        $site_permission = [ordered]@{
            Url = $null;
            WebPermissions = $null;
            Permissions = $null;
        }
        #Set generic list
        $permissions = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]

    }
    Process{
        #Check for objectType
        if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            #Add to dict
            $site_permission.Url = $Web.Url;
            $msg = @{
                MessageData = ($message.SPSGetPermissions -f $Web.Url);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('SPSSitePermission');
            }
            Write-Information @msg
            #Set query
            $p = @{
                Object = $Web;
                Authentication = $Authentication;
                Endpoint = $Web.Url;
                IncludeInheritedPermission = $SiteInheritedPermission;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $perms = Get-MonkeyCSOMObjectPermission @p
            if($perms){
                $site_permission.WebPermissions = $perms
            }
            #Check for list permission
            if($PSBoundParameters.ContainsKey('ScanFiles') -or $PSBoundParameters.ContainsKey('ScanFolders') -or $PSBoundParameters.ContainsKey('ListInheritedPermission')){
                #Get lists
                $p = @{
                    Authentication = $Authentication;
                    Web = $Web;
                    ExcludeInternalLists = $true;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $lists = Get-MonkeyCSOMList @p
                if($lists){
                    if($PSBoundParameters.ContainsKey('ListInheritedPermission') -and $PSBoundParameters.ListInheritedPermission){
                        #Get inherited permission for lists
                        foreach($list in @($lists)){
                            $p = @{
                                Object = $list;
                                Authentication = $Authentication;
                                Endpoint = $Web.Url;
                                IncludeInheritedPermission = $ListInheritedPermission;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $perms = Get-MonkeyCSOMObjectPermission @p
                            if($perms){
                                #Add to list
                                foreach($perm in $perms){
                                    [void]$permissions.Add($perm)
                                }
                            }
                            #Get listitems
                            if($PSBoundParameters.ContainsKey('ScanFiles') -or $PSBoundParameters.ContainsKey('ScanFolders')){
                                $p = @{
                                    Authentication = $Authentication;
                                    List = $list;
                                    Endpoint = $Web.Url;
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                }
                                $listItems = Get-MonkeyCSOMListItem @p
                                if($listItems){
                                    if($PSBoundParameters.ContainsKey('ScanFiles') -and $PSBoundParameters.ScanFiles){
                                        #Scan files
                                        $p = @{
                                            Authentication = $Authentication;
                                            ListItems = $listItems;
                                            Endpoint = $Web.Url;
                                            IncludeInheritedPermission = $FileInheritedPermission;
                                            InformationAction = $O365Object.InformationAction;
                                            Verbose = $O365Object.verbose;
                                            Debug = $O365Object.debug;
                                        }
                                        $perms = Get-MonkeyCSOMListItemPermission @p
                                        if($perms){
                                            #Add to list
                                            foreach($perm in $perms){
                                                [void]$permissions.Add($perm)
                                            }
                                        }
                                    }
                                    if($PSBoundParameters.ContainsKey('ScanFolders') -and $PSBoundParameters.ScanFolders){
                                        #Scan folders
                                        $p = @{
                                            Authentication = $Authentication;
                                            ListItems = $listItems;
                                            Endpoint = $Web.Url;
                                            IncludeInheritedPermission = $FolderInheritedPermission;
                                            InformationAction = $O365Object.InformationAction;
                                            Verbose = $O365Object.verbose;
                                            Debug = $O365Object.debug;
                                        }
                                        $perms = Get-MonkeyCSOMFolderPermission @p
                                        if($perms){
                                            #Add to list
                                            foreach($perm in $perms){
                                                [void]$permissions.Add($perm)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                #Add to dict
                $site_permission.Permissions = $permissions
            }
        }
        else{
            $msg = @{
                MessageData = ($message.SPOInvalieWebObjectMessage);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $InformationAction;
                Tags = @('SPOInvalidWebObject');
            }
            Write-Warning @msg
        }
    }
    End{
        #return permissions
        New-Object -TypeName PsObject -Property $site_permission
    }
}
