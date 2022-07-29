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


Function Get-MonkeyPSListPermission{
    <#
        .SYNOPSIS
		Plugin to get information about O365 Sharepoint Online list item permissions

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online list item permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPSListPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $true, HelpMessage="Sharepoint Web Object")]
        [Object]$Web
    )
    Begin{
        #Getting environment
        #Get switchs
        $inherited = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.SitePermissions.IncludeInheritedPermissions)
        $scanFolders = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.SitePermissions.ScanFolders)
        $scanFiles = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.SitePermissions.ScanFiles)
        #Set array
        $all_permissions = @()
        #Set null
        $raw_lists = $null
        #Exclude system lists
        $ExcludedLists = @(
            "Access Requests","App Packages","appdata","appfiles",
            "Apps in Testing","Cache Profiles","Composed Looks",
            "Content and Structure Reports",
            "Content type publishing error log",
            "Converted Forms","Device Channels","Form Templates",
            "fpdatasources","Get started with Apps for Office and SharePoint",
            "List Template Gallery", "Long Running Operation Status",
            "Maintenance Log Library", "Images", "site collection images",
            "Master Docs","Master Page Gallery","MicroFeed","NintexFormXml",
            "Quick Deploy Items","Relationships List","Reusable Content",
            "Reporting Metadata", "Reporting Templates", "Search Config List",
            "Site Assets","Preservation Hold Library","Site Pages",
            "Solution Gallery","Style Library","Suggested Content Browser Locations",
            "Theme Gallery", "TaxonomyHiddenList","User Information List",
            "Web Part Gallery","wfpub","wfsvc","Workflow History",
            "Workflow Tasks", "Pages","SitePages","FormServerTemplates"
        )
    }
    Process{
        if($null -ne $Web.psobject.properties.Item('_ObjectType_') -and $web._ObjectType_ -eq 'SP.Web'){
            $msg = @{
                MessageData = ($message.SPSGetListsForWeb -f $Web.Url);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('SPSLists');
            }
            Write-Information @msg
            #Get all lists
            $param = @{
                Authentication = $Authentication;
                clientObject = $Web;
                properties = 'Lists';
                executeQuery= $true;
                endpoint = $Web.Url;
            }
            $raw_lists = Get-MonkeySPSProperty @param
        }
        if($null -ne $raw_lists){
            #Get Items
            ForEach($list in $raw_lists.Lists){
                #Exclude System Lists
                if($ExcludedLists -notcontains $list.Title){
                    $msg = @{
                        MessageData = ($message.SPSWorkingMessage -f $list.Title, "list item");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $InformationAction;
                        Tags = @('SPSListInfo');
                    }
                    Write-Verbose @msg
                    if($scanFolders){
                        $msg = @{
                            MessageData = ($message.SPSScanningMessage -f "folders", $list.Title);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $InformationAction;
                            Tags = @('SPSListInfo');
                        }
                        Write-Verbose @msg
                        $param = @{
                            Authentication = $Authentication;
                            Endpoint = $Web.Url;
                            List = $list;
                        }
                        $all_permissions += Get-MonkeyPSFolderPermission @param
                    }
                    if($inherited){
                        $msg = @{
                            MessageData = ($message.SPSScanningMessage -f "inherited permissions", $list.Title);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $InformationAction;
                            Tags = @('SPSListInfo');
                        }
                        Write-Verbose @msg
                        $param = @{
                            Authentication = $Authentication;
                            endpoint = $Web.Url;
                            object = $list;
                        }
                        $all_permissions += Get-MonkeyPSPermission @param
                    }
                    if($scanFiles){
                        $msg = @{
                            MessageData = ($message.SPSScanningMessage -f "files", $list.Title);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $InformationAction;
                            Tags = @('SPSListInfo');
                        }
                        Write-Verbose @msg
                        $param = @{
                            Authentication = $Authentication;
                            Endpoint = $Web.Url;
                            List = $list;
                        }
                        $all_permissions += Get-MonkeyPSFilePermission @param
                    }
                }
            }
        }
    }
    End{
        if($null -ne $all_permissions){
            return $all_permissions
        }
    }
}
