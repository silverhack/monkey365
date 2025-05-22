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


Function Get-MonkeyCSOMWebsForUser{
    <#
        .SYNOPSIS
		Get all Sharepoint Online webs for currently logged user

        .DESCRIPTION
		Get all Sharepoint Online webs for currently logged user

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMWebsForUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Object]])]
    Param(
        [parameter(Mandatory=$false, ParameterSetName = 'Sites', HelpMessage="Scan Sites")]
        [String[]]$Sites,

        [parameter(Mandatory=$false, HelpMessage="Scan Sites")]
        [Switch]$ScanSites,

        [parameter(Mandatory=$false, HelpMessage="Recursive scan")]
        [Switch]$Recurse,

        [Parameter(Mandatory=$false, HelpMessage="Subsite depth limit recursion")]
        [int32]$Limit
    )
    Begin{
        #Get Access Token for Sharepoint
        $sps_auth = $O365Object.auth_tokens.SharePointOnline
        #Set new list
        $all_webs = [System.Collections.Generic.List[System.Object]]::new()
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'Sites'){
            foreach($site in $PSBoundParameters.Sites){
                $p = @{
                    Authentication = $sps_auth;
                    Endpoint = $site;
                    Recurse = $Recurse;
                    Limit = $Limit;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $raw_web = Get-MonkeyCSOMWeb @p
                if($raw_web){
                    foreach($web in @($raw_web)){
                        [void]$all_webs.Add($web)
                    }
                }
            }
        }
        else{
            #Get all sites for current user
            $p = @{
                ScanSites = $ScanSites;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $all_sites = Get-MonkeyCSOMSitesForUser @p
            #Convert to SP.Web
            if($all_sites){
                foreach($site in @($all_sites)){
                    if($null -ne $site.PSObject.Properties.Item('_ObjectType_')){
                        $endpoint = $site.Url
                    }
                    elseif($null -ne $site.PSObject.Properties.Item('SiteName')){
                        $endpoint = $site.SiteName
                    }
                    else{
                        $endpoint = $null
                    }
                    if($null -ne $endpoint){
                        $p = @{
                            Authentication = $sps_auth;
                            Endpoint = $endpoint;
                            Recurse = $Recurse;
                            Limit = $Limit;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
                        }
                        $raw_web = Get-MonkeyCSOMWeb @p
                        if($raw_web){
                            foreach($web in @($raw_web)){
                                [void]$all_webs.Add($web)
                            }
                        }
                    }
                }
            }
        }
    }
    End{
        return $all_webs
    }
}

