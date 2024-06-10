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

Function Get-MonkeyCSOMList {
    <#
        .SYNOPSIS
		Get SharePoint Online lists from Site

        .DESCRIPTION
		Get SharePoint Online lists from Site

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMList
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
	Param (
        [Parameter(Mandatory= $false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $false, ValueFromPipeline = $true, ParameterSetName = 'Web', HelpMessage="Sharepoint Web Object")]
        [Object]$Web,

        [Parameter(Mandatory=$false, ParameterSetName = 'Endpoint',  HelpMessage="Url")]
        [String]$Endpoint,

        [Parameter(Mandatory=$false, HelpMessage="Lists to filter")]
        [string[]]$Filter,

        [Parameter(Mandatory= $false, HelpMessage="Exclude SharePoint Online internal lists")]
        [Switch]$ExcludeInternalLists
    )
    Begin{
        #Set excluded lists
        $excluded_lists = @(
            "Access Requests","App Packages","appdata",
            "appfiles", "Apps in Testing","Cache Profiles",
            "Composed Looks","Content and Structure Reports",
            "Content type publishing error log",
            "Converted Forms","Device Channels",
            "Form Templates", "fpdatasources",
            "Get started with Apps for Office and SharePoint",
            "List Template Gallery", "Long Running Operation Status",
            "Maintenance Log Library", "Images",
            "site collection images","Master Docs",
            "Master Page Gallery","MicroFeed","NintexFormXml",
            "Quick Deploy Items","Relationships List",
            "Reusable Content", "Reporting Metadata",
            "Reporting Templates", "Search Config List",
            "Site Assets","Preservation Hold Library",
            "Site Pages", "Solution Gallery",
            "Style Library","Suggested Content Browser Locations",
            "Theme Gallery", "TaxonomyHiddenList",
            "User Information List","Web Part Gallery",
            "wfpub","wfsvc","Workflow History",
            "Workflow Tasks", "Pages","SitePages",
            "FormServerTemplates",,"SharePointHomeOrgLinks",
            "SharePointHomeCacheList"
        )
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'Current'){
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMWeb" -Params $PSBoundParameters
            $_Web = Get-MonkeyCSOMWeb @p
            if($_Web){
                $_Web | Get-MonkeyCSOMList @PSBoundParameters
                return
            }
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'Endpoint'){
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMWeb" -Params $PSBoundParameters
            $_Web = Get-MonkeyCSOMWeb @p
            if($_Web){
                #Remove Endpoint
                [void]$PSBoundParameters.Remove('Endpoint')
                $_Web | Get-MonkeyCSOMList @PSBoundParameters
                return
            }
        }
        Else{
            foreach($_Web in @($PSBoundParameters['Web'])){
                $objectType = $_Web | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
                if ($null -ne $objectType -and $objectType -eq 'SP.Web'){
                    $p = Set-CommandParameter -Command "Get-MonkeyCSOMProperty" -Params $PSBoundParameters
                    #Add endpoint
                    if($null -eq $p.Item('Endpoint')){
                        [void]$p.Add('Endpoint', $_Web.Url);
                    }
                    #Add ClientObject
                    [void]$p.Add('ClientObject', $_Web);
                    #Add Properties
                    [void]$p.Add('Properties', 'Lists');
                    #Get lists
                    $all_lists = Get-MonkeyCSOMProperty @p
                    #Check for lists
                    If ($null -ne $all_lists){
                        $all_lists = $all_lists.Lists
                        if($PSBoundParameters.ContainsKey('ExcludeInternalLists') -and $PSBoundParameters.ExcludeInternalLists){
                            #Remove excluded lists
                            $all_lists = $all_lists.Where({$_.Hidden -eq $False -and $excluded_lists -notcontains $_.Title})
                        }
                        if($PSBoundParameters.ContainsKey('Filter') -and $PSBoundParameters['Filter'] -and $PSBoundParameters.Filter.Count -gt 0){
                            #Filter lists
                            $all_lists = $all_lists.Where({$PSBoundParameters['Filter'] -contains $_.Title});
                        }
                        #return object
                        Write-Output $all_lists
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
                }
            }
        }
    }
    End{
        #Nothing to do here
    }
}