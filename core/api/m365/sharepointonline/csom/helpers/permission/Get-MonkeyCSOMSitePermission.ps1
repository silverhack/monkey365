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


Function Get-MonkeyCSOMSitePermission{
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
            File Name	: Get-MonkeyCSOMSitePermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [Parameter(Mandatory= $False, ParameterSetName = 'Site', ValueFromPipeline = $true, HelpMessage="SharePoint Site Object")]
        [Object]$Site,

        [Parameter(Mandatory= $False, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, ParameterSetName = 'Endpoint', HelpMessage="Endpoint")]
        [String]$Endpoint,

        [parameter(Mandatory=$false, HelpMessage="Recursive search")]
        [Switch]$Recurse,

        [Parameter(Mandatory=$false, HelpMessage="Subsite depth limit recursion")]
        [int32]$Limit = 10,

        [parameter(Mandatory=$false, HelpMessage="Include lists")]
        [Switch]$IncludeLists,

        [parameter(Mandatory=$false, HelpMessage="Include lists")]
        [Switch]$IncludeItems,

        [parameter(Mandatory=$false, HelpMessage="Include lists")]
        [Switch]$ExcludeFolders,

        [Parameter(Mandatory=$false, HelpMessage="Lists to filter")]
        [string[]]$Filter,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions")]
        [Switch]$IncludeInheritedPermission
    )
    Process{
        If($PSCmdlet.ParameterSetName -eq "Current" -or $PSCmdlet.ParameterSetName -eq 'Endpoint'){
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMSite" -Params $PSBoundParameters
            $_Site = Get-MonkeyCSOMSite @p
            if($null -ne $_Site){
                 $_Site | Get-MonkeyCSOMSitePermission @PSBoundParameters
            }
            return
        }
        foreach($_Site in @($PSBoundParameters['Site']).Where({$null -ne $_})){
            $objectType = $_Site | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
            if ($null -ne $objectType -and $objectType -eq 'SP.Site'){
                #Get Site collection administrators
                #Get command params
                $sparams = Set-CommandParameter -Command "Get-MonkeyCSOMSiteCollectionAdministrator" -Params $PSBoundParameters
                #Add Object
                $sparams.Item('Site') = $_Site
                #Get Site collection administrators
                $siteAdmins = Get-MonkeyCSOMSiteCollectionAdministrator @sparams;
                $saPerms = [PsCustomObject]@{
                    Name = 'Site Collection Administrators';
                    Description = 'Full Control to manage the SharePoint site collection';
                }
                #Set Object
                $permObject = $_Site | Get-MonkeyCSOMObjectType | New-MonkeyCSOMPermissionObject
                $permObject.objectType = "Site Collection";
                $permObject.HasUniquePermissions = $true;
                $permObject.AppliedTo = "Site Collection Administrators";
                $permObject.Permissions = $saPerms;
                $permObject.GrantedThrough = "Direct Permissions";
                $permObject.RoleAssignment = $null;
                $permObject.Description = $saPerms.Description;
                $permObject.members = $siteAdmins;
                $permObject.rawObject = $_Site;
                #rerturn Object
                Write-Output $permObject -NoEnumerate;
                #Check for web
                $p = Set-CommandParameter -Command "Get-MonkeyCSOMWeb" -Params $PSBoundParameters
                #Remove recurse and limit
                [void]$p.Remove('Recurse');
                [void]$p.Remove('Limit');
                #Add Endpoint
                $p.Item('Endpoint') = $_Site.Url;
                $_Web = Get-MonkeyCSOMWeb @p
                if($null -ne $_Web){
                    #Get Web permissions
                    $webParam = Set-CommandParameter -Command "Get-MonkeyCSOMWebPermission" -Params $PSBoundParameters
                    $_Web | Get-MonkeyCSOMWebPermission @webParam
                }
            }
            Else{
                $msg = @{
                    MessageData = ($message.SPOInvalidSiteObjectMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyCSOMInvalidSiteObject');
                }
                Write-Warning @msg
            }
        }
    }
}

