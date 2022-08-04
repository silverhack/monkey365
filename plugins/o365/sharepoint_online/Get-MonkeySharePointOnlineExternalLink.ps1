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


Function Get-MonkeySharePointOnlineExternalLink{
    <#
        .SYNOPSIS
		Plugin to get information about O365 Sharepoint Online external links

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online external links

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineExternalLink
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
        [String]$pluginId
    )
    Begin{
        #Get Access Token for Sharepoint
        $sps_auth = $O365Object.auth_tokens.SharePointOnline
        #Set array
        $all_external_links = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Sharepoint Online external links", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('SPSExernalLinks');
        }
        Write-Information @msg
        #Get all webs for user
        $allowed_sites = Get-MonkeySPSWebsForUser
        #Getting external users for each site
        foreach($web in $allowed_sites){
            #Getting all lists
            $msg = @{
                MessageData = ($message.SPSGetListsForWeb -f $web.url);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('SPSExternalUsersInfo');
            }
            Write-Information @msg
            $param = @{
                Authentication = $sps_auth;
                clientObject = $web;
                properties = 'Lists';
                executeQuery= $true;
                endpoint = $web.Url;
            }
            $all_lists = Get-MonkeySPSProperty @param
            if($all_lists){
                $documentLibrary = $all_lists.Lists | Where-Object {$_.Title -eq 'Documents'}
                if($documentLibrary){
                    #Get All items
                    $param = @{
                        Authentication = $sps_auth;
                        endpoint = $web.Url;
                        list = $documentLibrary;
                    }
                    $items = Get-MonkeySPSListItem @param
                    if($items){
                        foreach($item in $items){
                            #Get RoleAssignments
                            $param = @{
                                clientObject = $item;
                                properties = "HasUniqueRoleAssignments";
                                Authentication = $sps_auth;
                                endpoint = $web.Url;
                                executeQuery = $True;
                            }
                            $permissions = Get-MonkeySPSProperty @param
                            if($permissions.HasUniqueRoleAssignments){
                                #Get sharing info
                                $item_id = Find-ID -string $item.UniqueId
                                $msg = @{
                                    MessageData = ($message.SPSGetSharingInfoForItem -f $item_id);
                                    callStack = (Get-PSCallStack | Select-Object -First 1);
                                    logLevel = 'verbose';
                                    InformationAction = $InformationAction;
                                    Tags = @('SPSExternalSharingInfo');
                                }
                                Write-Verbose @msg
                                $param = @{
                                    Authentication = $sps_auth;
                                    endpoint = $web.Url;
                                    object_id = $item._ObjectIdentity_;
                                }
                                $sharingInfo = Get-MonkeyPSSharingInfo @param
                                ForEach($sharedLink in $sharingInfo.SharingLinks){
                                    if($sharedLink.Url){
                                        if($sharedLink.IsEditLink){
                                            $linkAccess="Edit"
                                        }
                                        elseif($sharedLink.IsReviewLink){
                                            $linkAccess="Review"
                                        }
                                        else{
                                            $linkAccess="ViewOnly"
                                        }
                                        #Set shared link info
                                        $all_external_links += New-Object PSObject -property $([ordered]@{
                                                Site = $web.Url;
                                                FileID = $item.UniqueId
                                                Name  = $item.FileLeafRef
                                                FileSystemObjectType = [FileSystemObjectType]$item.FileSystemObjectType
                                                RelativeURL = $item.FileRef
                                                CreatedByEmail = $item.Author.Email
                                                CreatedOn  = $item.Created
                                                Modified   = $item.Modified
                                                ModifiedByEmail  = $item.Editor.Email
                                                SharedLink  = $sharedLink.Url
                                                SharedLinkAccess  =  $linkAccess
                                                RequiresPassword  =  $sharedLink.RequiresPassword
                                                BlocksDownload  =  $sharedLink.BlocksDownload
                                                SharedLinkType  = [SharingLinkKind]$sharedLink.LinkKind
                                                AllowsAnonymousAccess  = $sharedLink.AllowsAnonymousAccess
                                                IsActive  = $sharedLink.IsActive
                                                rawSharingInfoObject  = $sharingInfo
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    End{
        if($all_external_links){
            $all_external_links.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.ExternalLinks')
            [pscustomobject]$obj = @{
                Data = $all_external_links
            }
            $returnData.o365_spo_external_links = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online external links", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('SPSExternalLinksEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
