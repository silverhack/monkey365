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

Function Get-SharepointAdminUrl{
    <#
     .SYNOPSIS
     Get Sharepoint admin Url from Global Tenant var

     .DESCRIPTION
     The Get-SharepointAdminUrl function lets you get the Sharepoint Admin URL from global Tenant var

     .EXAMPLE
     Get-SharepointAdminUrl

     This example gets sharepoint Admin URL from verifiedDomains var
    #>
    [CmdletBinding()]
    Param(
        # Endpoint
        [Parameter(Mandatory = $true, HelpMessage = 'Endpoint')]
        [String]$Endpoint,

        [Parameter(Mandatory = $false, HelpMessage = 'Environment')]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment = "AzurePublic"
    )
    try{
        $sharePointAdminUrl = $null
        switch ($Environment) {
            "AzurePublic"
            {
                $sharePointAdminUrl = ("https://{0}-admin.sharepoint.com" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureUSGovernment"
            {
                $sharePointAdminUrl = ("https://{0}-admin.sharepoint.us" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureGermany"
            {
                $sharePointAdminUrl = ("https://{0}-admin.sharepoint.de" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureChina"{
                $sharePointAdminUrl = ("https://{0}-admin.sharepoint.cn" -f $Endpoint.split(".")[0]);
                break
            }
            "Default"
            {
                $sharePointAdminUrl = ("https://{0}-admin.sharepoint.com" -f $Endpoint.split(".")[0]);
                break
            }
        }
        return $sharePointAdminUrl
    }
    catch{
        Write-Debug $_
    }
}


