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


Function Invoke-MonkeyPSCrawlWeb{
    <#
        .SYNOPSIS
		Plugin to get information about O365 SharePoint Online sites, including List items, files, folders, etc..

        .DESCRIPTION
		Plugin to get information about O365 SharePoint Online sites, including List items, files, folders, etc..

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyPSCrawlWeb
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="SharePoint Web Object")]
        [Object]$Web
    )
    Begin{
        #Get Access Token for SharePoint
        $sps_auth = $O365Object.auth_tokens.SharePointOnline
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
        if($null -ne $Web -and $null -ne $Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            #Set array
            $site_info = [ordered]@{
                Url = $Web.Url;
            }
            #Get all list items
            $param = @{
                Authentication = $sps_auth;
                clientObject = $Web;
                properties = 'Lists';
                executeQuery= $true;
                endpoint = $Web.Url;
            }
            $raw_lists = Get-MonkeySPSProperty @param
            if($null -ne $raw_lists){
                $parsed_lists = @()
                #Get Items
                ForEach($list in $raw_lists.Lists){
                    #Exclude System Lists
                    if($ExcludedLists -notcontains $list.Title){
                        #Get items in List
                        $param = @{
                            Authentication = $sps_auth;
                            endpoint = $Web.Url;
                            list = $list;
                        }
                        $raw_items = Get-MonkeySPSListItem @param
                        if($null -ne $raw_items){
                            $list | Add-Member NoteProperty -name Items -value $raw_items
                        }
                        else{
                            $list | Add-Member NoteProperty -name Items -value $null
                        }
                        $parsed_lists+=$list
                    }
                }
                #Add to dict
                $site_info.Add('ListItems',$parsed_lists)
            }
            else{
                $site_info.Add('ListItems',$null)
            }
        }
    }
    End{
        if($null -ne $site_info){
            #return custom object
            $site_obj = New-Object PSObject -Property $site_info
            return $site_obj
        }
    }
}
