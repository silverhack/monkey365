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


Function Get-MonkeyCSOMSiteAccessRequest{
    <#
        .SYNOPSIS
		Get Sharepoint Online site access request

        .DESCRIPTION
		Get Sharepoint Online site access request

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSiteAccessRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName  = $true, HelpMessage="SharePoint Web Object")]
        [Object]$Web
    )
    Begin{
        #Set generic list
        $siteAccessList = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
    }
    Process{
        #Check for objectType
        if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            $access_request = $null;
            #Get Lists
            $p = @{
				Authentication = $Authentication;
				ClientObject = $Web;
				Properties = 'Lists';
				Endpoint = $Web.Url;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
			}
			$all_lists = Get-MonkeyCSOMProperty @p
            if($all_lists){
                #Get access request list
                $access_request = $all_lists.Lists | Where-Object { $_.Title -eq 'Access Requests' }
            }
            if($null -ne $access_request){
                foreach($ar in @($access_request)){
                    #Getting access requests
					$msg = @{
						MessageData = ($message.SPSCheckSiteAccessRequests -f $Web.Url);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'verbose';
						InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
						Tags = @('SPSAccessRequestInfo');
					}
					Write-Verbose @msg
                    $p = @{
                        Authentication = $Authentication;
                        List = $ar;
                        Endpoint = $Web.Url;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $access_list = Get-MonkeyCSOMListItem @p
                    if($null -ne $access_list){
                        foreach($access in @($access_list)){
                            $access_dict = [ordered]@{
                                Title = $access.Title;
                                Message = $access.Conversation;
							    RequestedObjectUrl = $access.RequestedObjectUrl.Url;
							    RequestedObjectTitle = $access.RequestedObjectTitle;
							    RequestedBy = $access.RequestedBy;
							    RequestedFor = $access.RequestedFor;
							    RequestDate = $access.RequestDate;
							    Expires = $access.Expires;
							    Status = [ChangeRequestStatus]$access.Status;
							    PermissionType = $access.PermissionType;
							    IsInvitation = $access.IsInvitation;
                                RawObject = $access;
                            }
                            #Add to List
                            $accessListObject = New-Object PSObject -Property $access_dict
                            [void]$siteAccessList.Add($accessListObject)
                        }
                    }
                }
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
        #return list
        #return , $siteAccessList
        Write-Output $siteAccessList -NoEnumerate
    }
}
