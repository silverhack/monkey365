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

Function New-MonkeyCSOMSiteAccesRequestObject {
<#
        .SYNOPSIS
		Create a new SharePoint Online Site Access object

        .DESCRIPTION
		Create a new SharePoint Online Site Access object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyCSOMSiteAccesRequestObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory= $True, ValueFromPipeline = $true, HelpMessage="SharePoint Object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $access_dict = [ordered]@{
                Title = $InputObject.Title;
                Message = $InputObject.Conversation;
				RequestedObjectUrl = $InputObject.RequestedObjectUrl.Url;
				RequestedObjectTitle = $InputObject.RequestedObjectTitle;
				RequestedBy = $InputObject.RequestedBy;
				RequestedFor = $InputObject.RequestedFor;
				RequestDate = $InputObject.RequestDate;
				Expires = $InputObject.Expires;
				Status = [ChangeRequestStatus]$InputObject.Status;
				PermissionType = $InputObject.PermissionType;
				IsInvitation = $InputObject.IsInvitation;
                RawObject = $InputObject;
            }
            #Create PsObject
            $access_obj = New-Object -TypeName PsObject -Property $access_dict
            #return object
            return $access_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.SPOPermissionObjectError -f $InputObject.ObjectType);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('MonkeyCSOMPermissionObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
