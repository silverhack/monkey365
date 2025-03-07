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
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory= $false, ParameterSetName = 'Web', ValueFromPipeline = $true, HelpMessage="Web object")]
        [Object]$Web,

        [Parameter(Mandatory=$false, ParameterSetName = 'EndPoint', HelpMessage="Url")]
        [String]$Endpoint,

        [Parameter(Mandatory=$false, HelpMessage="Lists to search")]
        [string[]]$Filter
    )
    Begin{
        $uniquePerms = $null;
        #Set job params
        $raParams = @{
	        Command = "Test-HasUniqueRoleAssignment";
            Arguments = $null;
	        Runspacepool = $O365Object.monkey_runspacePool;
	        ReuseRunspacePool = $true;
	        Debug = $O365Object.debug;
	        Verbose = $O365Object.verbose;
	        MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	        BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	        BatchSize = $O365Object.nestedRunspaces.BatchSize;
        }
        $siParams = @{
	        Command = "Get-MonkeyCSOMSharingInfo";
            Arguments = $null;
	        Runspacepool = $O365Object.monkey_runspacePool;
	        ReuseRunspacePool = $true;
	        Debug = $O365Object.debug;
	        Verbose = $O365Object.verbose;
	        MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	        BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	        BatchSize = $O365Object.nestedRunspaces.BatchSize;
        }
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'Endpoint' -or $PSCmdlet.ParameterSetName -eq 'Current'){
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMWeb" -Params $PSBoundParameters
            $_Web = Get-MonkeyCSOMWeb @p
            If($null -ne $_Web){
                #Remove Endpoint if exists
                [void]$PSBoundParameters.Remove('Endpoint');
                #Execute command
                $_Web | Get-MonkeyCSOMExternalLink @PSBoundParameters
                return
            }
        }
        foreach($_Web in @($PSBoundParameters['Web'])){
            $objectType = $_Web | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
            if ($null -ne $objectType -and $objectType -eq 'SP.Web'){
                #Get command param
                $p = Set-CommandParameter -Command "Get-MonkeyCSOMList" -Params $PSBoundParameters
                #Get command param
                $liarg = Set-CommandParameter -Command "Get-MonkeyCSOMListItem" -Params $PSBoundParameters
                #Exclude internal lists
                [void]$p.Add('ExcludeInternalLists',$true);
                #Add Web
                $p.Item('Web') = $_Web;
                #Execute command
                $allItems = Get-MonkeyCSOMList @p | Get-MonkeyCSOMListItem @liarg
                if($null -ne $allItems){
                    #Set new params
                    $p = Set-CommandParameter -Command "Test-HasUniqueRoleAssignment" -Params $PSBoundParameters
                    #Update Endpoint
                    $p.Item('Endpoint') = $_Web.Url;
                    #Add ClientObject
                    #$p.Item('ClientObject') = $_
                    #Set arguments
                    $raParams.Arguments = $p;
                    #Execute batch query
                    $uniquePerms = @($allItems).Where({( $_ | Invoke-MonkeyJob @raParams) -eq $true})
                }
                if($null -ne $uniquePerms){
                    #Set new params
                    $p = Set-CommandParameter -Command "Get-MonkeyCSOMSharingInfo" -Params $PSBoundParameters
                    #Update Endpoint
                    $p.Item('Endpoint') = $_Web.Url;
                    $siParams.Arguments = $p;
                    @($uniquePerms).ForEach({
                        $allLinks = $_._ObjectIdentity_ | Invoke-MonkeyJob @siParams;
                        foreach($elem in @($allLinks)){
                            foreach($sharedLink in $elem.SharingLinks){
                                if($sharedLink.IsEditLink){
                                    $linkAccess = "Edit"
                                }
                                elseif ($sharedLink.IsReviewLink) {
		                            $linkAccess = "Review"
		                        }
		                        else {
			                        $linkAccess = "ViewOnly"
		                        }
                                $LinkObject = $elem | New-MonkeyCSOMExternalLinkObject
                                if($LinkObject){
                                    $LinkObject.Site = $_Web.Url;
                                    $LinkObject.FileID = $_.UniqueId;
                                    $LinkObject.Name = $_.FileLeafRef;
                                    $LinkObject.FileSystemObjectType = [FileSystemObjectType]$_.FileSystemObjectType;
                                    $LinkObject.RelativeURL = $_.FileRef;
                                    $LinkObject.CreatedByEmail = $_.Author.email;
                                    $LinkObject.CreatedOn = $_.created;
                                    $LinkObject.Modified = $_.Modified;
                                    $LinkObject.ModifiedByEmail = $_.Editor.email;
                                    $LinkObject.SharedLinkAccess = $linkAccess;
                                    $LinkObject.SharedLink = $sharedLink.Url
			                        $LinkObject.RequiresPassword = $sharedLink.RequiresPassword
			                        $LinkObject.BlocksDownload = $sharedLink.BlocksDownload
			                        $LinkObject.SharedLinkType = [SharingLinkKind]$sharedLink.LinkKind
			                        $LinkObject.AllowsAnonymousAccess = $sharedLink.AllowsAnonymousAccess
			                        $LinkObject.IsActive = $sharedLink.IsActive
                                    $LinkObject.RawSharingInfoObject = $elem;
                                    $LinkObject
                                }
                            }
                        }
                    });
                }
            }
            Else{
                $msg = @{
                    MessageData = ($message.SPOInvalidWebObjectMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyCSOMInvalidWebObject');
                }
                Write-Warning @msg
                return
            }
        }
    }
    End{
    }
}


