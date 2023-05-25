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

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory= $true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $true, ParameterSetName = 'Web', HelpMessage="Sharepoint Web Object")]
        [Object]$Web,

        [Parameter(Mandatory=$True, ParameterSetName = 'Endpoint', HelpMessage="Url")]
        [String]$Endpoint,

        [Parameter(Mandatory=$false, HelpMessage="Lists to filter")]
        [string[]]$Filter,

        [Parameter(Mandatory= $false, HelpMessage="Exclude SharePoint Online internal lists")]
        [Switch]$ExcludeInternalLists
    )
    Begin{
        $all_lists = $null
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
        if($PSCmdlet.ParameterSetName -eq 'Endpoint'){
            #Get Web
            $p = @{
                Authentication = $Authentication;
                Endpoint = $Endpoint;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $Web = Get-MonkeyCSOMWeb @p
            if($Web){
                #Getting all lists
			    $msg = @{
				    MessageData = ($message.SPSGetListsForWeb -f $Web.url);
				    callStack = (Get-PSCallStack | Select-Object -First 1);
				    logLevel = 'info';
				    InformationAction = $O365Object.InformationAction;
				    Tags = @('SPSListsInfo');
			    }
			    Write-Information @msg
                #Get all lists
                $p = @{
                    ClientObject = $Web;
                    Properties = "Lists";
                    Authentication = $Authentication;
                    Endpoint = $Web.Url;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $all_lists = Get-MonkeyCSOMProperty @p
            }
        }
        elseif($PSCmdlet.ParameterSetName -eq 'Web'){
            #Check for objectType
            if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
                $msg = @{
				    MessageData = ($message.SPSGetListsForWeb -f $Web.url);
				    callStack = (Get-PSCallStack | Select-Object -First 1);
				    logLevel = 'info';
				    InformationAction = $O365Object.InformationAction;
				    Tags = @('SPSListsInfo');
			    }
			    Write-Information @msg
                $p = @{
                    ClientObject = $Web;
                    Properties = "Lists";
                    Authentication = $Authentication;
                    Endpoint = $Web.Url;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $all_lists = Get-MonkeyCSOMProperty @p
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
                break;
            }
        }
    }
    End{
        if($null -ne $all_lists){
            #Get lists
            $all_lists = $all_lists.Lists
            if($PSBoundParameters.ContainsKey('ExcludeInternalLists') -and $PSBoundParameters.ExcludeInternalLists){
                #Remove excluded lists
                $all_lists = $all_lists | Where-Object {$_.Hidden -eq $False -and $excluded_lists -notcontains $_.Title}
            }
            if($PSBoundParameters.ContainsKey('Filter') -and $PSBoundParameters.Filter.Count -gt 0){
                #Filter lists
                $all_lists = $all_lists | Where-Object {$PSBoundParameters['Filter'] -contains $_.Title}
            }
            return $all_lists
        }
    }
}