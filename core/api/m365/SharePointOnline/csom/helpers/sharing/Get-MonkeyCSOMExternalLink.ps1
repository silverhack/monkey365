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

Function Get-MonkeyCSOMExternalLink{
    <#
        .SYNOPSIS
        Get site's external links from SharePoint Online

        .DESCRIPTION
        Get site's external links from SharePoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMExternalLink
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory= $True, HelpMessage="Web object")]
        [Object]$Web,

        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [Parameter(Mandatory=$false, HelpMessage="Lists to search")]
        [string[]]$ListNames
    )
    Process{
        $all_shared_links = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
        if($null -ne $Web -and $null -ne $Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            #Get lists
            $p = @{
                Authentication = $Authentication;
                Web = $Web;
                Filter = $ListNames;
                ExcludeInternalLists = $True;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            #Execute query
            $all_lists = Get-MonkeyCSOMList @p
            #Iterate over all lists
            if($all_lists){
                foreach($list in @($all_lists)){
                    #Get items
                    $p = @{
                        Authentication = $Authentication;
                        List = $list;
                        EndPoint = $Web.Url;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $listItems = Get-MonkeyCSOMListItem @p
                    if($listItems){
                        foreach($item in @($listItems)){
                            #Get sharing info
						    $item_id = Find-ID -String $item.UniqueId
						    $msg = @{
							    MessageData = ($message.SPSGetSharingInfoForItem -f $item_id);
							    callStack = (Get-PSCallStack | Select-Object -First 1);
							    logLevel = 'verbose';
							    InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
							    Tags = @('SPSExternalSharingInfo');
						    }
						    Write-Verbose @msg
                            #Check if roleAssignments
                            $param = @{
                                ClientObject = $item;
                                Properties = "HasUniqueRoleAssignments";
                                Authentication = $Authentication;
                                Endpoint = $Web.Url;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $permissions = Get-MonkeyCSOMProperty @param
                            if($null -ne $permissions -and $permissions.HasUniqueRoleAssignments){
                                #Get Sharing Info
                                $p = @{
                                    Authentication = $Authentication;
                                    ObjectId = $item._ObjectIdentity_;
                                    EndPoint = $Web.Url;
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                }
                                $sharingInfo = Get-MonkeyCSOMSharingInfo @p
                                if($sharingInfo){
                                    foreach ($sharedLink in $sharingInfo.SharingLinks){
                                        if($sharedLink.url){
                                            if($sharedLink.IsEditLink){
                                                $linkAccess = "Edit"
                                            }
                                            elseif ($sharedLink.IsReviewLink) {
		                                        $linkAccess = "Review"
		                                    }
		                                    else {
			                                    $linkAccess = "ViewOnly"
		                                    }
                                            $LinkObject = [ordered]@{
                                                Site = $web.Url;
                                                FileID = $item.UniqueId
                                                IsFolder = $sharingInfo.IsFolder
                                                AnonymousEditLink = $sharingInfo.AnonymousEditLink
                                                AnonymousViewLink = $sharingInfo.AnonymousViewLink
                                                CanBeShared = $sharingInfo.CanBeShared
                                                IsSharedWithGuest = $sharingInfo.IsSharedWithGuest
                                                IsSharedWithMany = $sharingInfo.IsSharedWithMany
                                                IsSharedWithSecurityGroup = $sharingInfo.IsSharedWithSecurityGroup
			                                    Name = $item.FileLeafRef
			                                    FileSystemObjectType = [FileSystemObjectType]$item.FileSystemObjectType
			                                    RelativeURL = $item.FileRef
			                                    CreatedByEmail = $item.Author.email
			                                    CreatedOn = $item.created
			                                    Modified = $item.Modified
			                                    ModifiedByEmail = $item.Editor.email
			                                    SharedLink = $sharedLink.Url
			                                    SharedLinkAccess = $linkAccess
			                                    RequiresPassword = $sharedLink.RequiresPassword
			                                    BlocksDownload = $sharedLink.BlocksDownload
			                                    SharedLinkType = [SharingLinkKind]$sharedLink.LinkKind
			                                    AllowsAnonymousAccess = $sharedLink.AllowsAnonymousAccess
			                                    IsActive = $sharedLink.IsActive
			                                    RawSharingInfoObject = $sharingInfo
                                            }
                                            #return PsObject
                                            $obj = New-Object -TypeName PsObject -Property $LinkObject
                                            [void]$all_shared_links.Add($obj)
                                        }
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
        #Nothing to do here
        return $all_shared_links
    }
}
