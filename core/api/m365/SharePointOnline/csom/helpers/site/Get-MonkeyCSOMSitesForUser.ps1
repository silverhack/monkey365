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


Function Get-MonkeyCSOMSitesForUser{
    <#
        .SYNOPSIS
		Get all Sharepoint Online sites for currently logged user

        .DESCRIPTION
		Get all Sharepoint Online sites for currently logged user

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSitesForUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param(
        [Parameter(Mandatory=$false, ParameterSetName = 'Webs', HelpMessage="SharePoint Online Webs")]
        [System.Array]$Webs,

        [Parameter(Mandatory=$false, HelpMessage="Scan sites")]
        [Switch]$ScanSites
    )
    Begin{
        #Set new list
        $all_sites = New-Object System.Collections.Generic.List[System.Object]
        #Get Access Token for Sharepoint
        $sps_auth = $O365Object.auth_tokens.SharepointOnline
        #Set null
        $raw_sites = $null
        if($PSCmdlet.ParameterSetName -eq 'Webs'){
            $raw_sites = $Webs | Select-Object -ExpandProperty Url -ErrorAction Ignore
        }
        else{
            if($PSBoundParameters.ContainsKey('ScanSites') -and $PSBoundParameters.ScanSites){
                if($O365Object.isSharePointAdministrator){
                    #Get All site properties
                    $p = @{
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $raw_sites = Get-MonkeyCSOMSiteProperty @p
                    if($null -ne $raw_sites){
                        #removing sites with search templates, onedrive templates, etc..
                        $raw_sites = $raw_sites | Where-Object {$_.Template -notlike "SRCHCEN#0" -and $_.Template -notlike "SPSMSITEHOST*"}
                    }
                    #Get unit sites
                    $raw_sites = $raw_sites | Select-Object -ExpandProperty Url -ErrorAction Ignore
                }
                else{
                    #User is potentially not member of any administrative group. Warning message
                    $msg = @{
                        MessageData = ($message.UnableToSitePropertiesForUser -f $O365Object.userPrincipalName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('SPSUnableToGetSites');
                    }
                    Write-Warning @msg
                    #Info message
                    $msg = @{
                        MessageData = ($message.GetSitesUsingSharePointSearchApi);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('SPSSiteSearchUsingAPI');
                    }
                    Write-Information @msg
                    #SPS auth object
                    $p = @{
                        Authentication = $sps_auth;
                        ScanSubSites = $ScanSubSites;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $raw_sites = Get-MonkeySPOApiSite @p
                    if($raw_sites){
                        #removing sites with search templates, onedrive templates, etc..
                        $raw_sites = $raw_sites | Where-Object {$_.WebTemplate -notlike "SPSPERS"}
                        #Get unit sites
                        $SiteNames = $raw_sites | Select-Object -ExpandProperty SiteName -ErrorAction Ignore
                        $SpWebUrl = $raw_sites | Select-Object -ExpandProperty SPWebUrl -ErrorAction Ignore
                        #combine objects
                        $raw_sites = $SiteNames + $SpWebUrl
                        #remove duplicate
                        $raw_sites = $raw_sites | Select-Object -Unique
                    }
                }
            }
            else{
                #Get current site
                $p = @{
                    Authentication = $sps_auth;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $raw_sites = Get-MonkeyCSOMSite @p
                if($raw_sites){
                    $raw_sites = $raw_sites.Url
                }
            }
        }
    }
    Process{
        #Convert urls to SP.Site
        foreach($url in @($raw_sites)){
            $p = @{
                Authentication = $sps_auth;
                Endpoint = $url;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $raw_site = Get-MonkeyCSOMSite @p
            if($raw_site){
                [void]$all_sites.Add($raw_site)
            }
        }
    }
    End{
        return $all_sites
    }
}
