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

Function New-MonkeyCSOMExternalLinkObject {
<#
        .SYNOPSIS
		Create a new SharePoint Online External Link object

        .DESCRIPTION
		Create a new SharePoint Online External Link object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyCSOMExternalLinkObject
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
            $LinkDict = [ordered]@{
                Site = $null;
                FileID = $null;
                IsFolder = $InputObject.IsFolder
                AnonymousEditLink = $InputObject.AnonymousEditLink
                AnonymousViewLink = $InputObject.AnonymousViewLink
                CanBeShared = $InputObject.CanBeShared
                IsSharedWithGuest = $InputObject.IsSharedWithGuest
                IsSharedWithMany = $InputObject.IsSharedWithMany
                IsSharedWithSecurityGroup = $InputObject.IsSharedWithSecurityGroup
			    Name = $null;
			    FileSystemObjectType = $null;
			    RelativeURL = $null;
			    CreatedByEmail = $null;
			    CreatedOn = $null;
			    Modified = $null;
			    ModifiedByEmail = $null;
			    SharedLink = $null;
			    SharedLinkAccess = $null;
			    RequiresPassword = $null;
			    BlocksDownload = $null;
			    SharedLinkType = $null;
			    AllowsAnonymousAccess = $null;
			    IsActive = $null;
			    RawSharingInfoObject = $InputObject;
            }
            #Create PsObject
            $LinkObj = New-Object -TypeName PsObject -Property $LinkDict
            #return object
            return $LinkObj
        }
        catch{
            $msg = @{
			    MessageData = ($message.SPOPermissionObjectError -f $InputObject.ObjectType);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('MonkeyCSOMExternalLinkObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
