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


Function Get-MonkeySPSWebsForUser{
    <#
        .SYNOPSIS
		Plugin to get information about O365 Sharepoint Online webs for user

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online webs for user

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPSWebsForUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Begin{
        #Get Access Token for Sharepoint
        $sps_auth = $O365Object.auth_tokens.SharepointOnline
        #Get Access Token for Sharepoint admin
        $sps_admin_auth = $O365Object.auth_tokens.SharepointAdminOnline
        #Get switchs
        $scanSites = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.ScanSites)
        $recurseScan = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Subsites.Recursive)
        $depthScan = $O365Object.internal_config.o365.SharePointOnline.Subsites.Depth
        #Set array
        $all_sites = @()
        if($scanSites){
            #Get all sites
            $param = @{
                Authentication = $sps_admin_auth;
            }
            #call SPS
            $raw_sites = Get-MonkeySPSSiteProperty @param
            if($raw_sites){
                #removing sites with search templates, onedrive templates, etc..
                $raw_sites = $raw_sites | Where-Object {$_.Template -notlike "SRCHCEN#0" -and $_.Template -notlike "SPSMSITEHOST*"}
            }
            if(!$raw_sites){
                #User is potentially not member of any administrative group. Warning message
                $msg = @{
                    MessageData = ($message.UnableToSitePropertiesForUser -f $O365Object.userPrincipalName);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $InformationAction;
                    Tags = @('SPSUnableToGetSites');
                }
                Write-Warning @msg
                #Info message
                $msg = @{
                    MessageData = ($message.GetSitesUsingSharePointSearchApi);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('SPSSiteSearchUsingAPI');
                }
                Write-Information @msg
                #Perform query
                $param = @{
                    Authentication = $sps_auth;
                }
                $raw_sites = Get-MonkeySPSApiSite @param
                if($raw_sites){
                    #removing sites with search templates, onedrive templates, etc..
                    $raw_sites = $raw_sites | Where-Object {$_.WebTemplate -notlike "SPSPERS"}
                }
            }
        }
        else{
            #Get current site
            $param = @{
                Authentication = $sps_auth;
            }
            $raw_sites = Get-MonkeySPSSite @param
        }
    }
    Process{
        #Recurse scan to get all webs
        if($recurseScan){
            foreach($site in $raw_sites){
                if($null -ne $site.PSObject.Properties.Item('_ObjectType_')){
                    $endpoint = $site.Url
                }
                else{
                    $endpoint = $site.SiteName
                }
                $param = @{
                    Authentication = $sps_auth;
                    endpoint = $endpoint;
                    recurse = $recurseScan;
                    limit = $depthScan;
                }
                $all_sites+= Get-MonkeySPSWeb @param
            }
        }
        else{
            #Add to array
            $all_sites+=$raw_sites
        }
    }
    End{
        return $all_sites
    }
}
