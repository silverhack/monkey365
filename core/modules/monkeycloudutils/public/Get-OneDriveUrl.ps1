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

Function Get-OneDriveUrl{
    <#
     .SYNOPSIS
     Get Onedrive Url from Global Tenant var

     .DESCRIPTION
     The Get-OneDriveUrl function lets you get the OneDrive URL from global Tenant var

     .EXAMPLE
     Get-OneDriveUrl

     This example gets OneDrive URL from verifiedDomains var
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
        $sharePointUrl = $null
        switch ($Environment) {
            "AzurePublic"
            {
                $sharePointUrl = ("https://{0}-my.sharepoint.com" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureUSGovernment"
            {
                $sharePointUrl = ("https://{0}-my.sharepoint.us" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureGermany"
            {
                $sharePointUrl = ("https://{0}-my.sharepoint.de" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureChina"{
                $sharePointUrl = ("https://{0}-my.sharepoint.cn" -f $Endpoint.split(".")[0]);
                break
            }
            "Default"
            {
                $sharePointUrl = ("https://{0}-my.sharepoint.com" -f $Endpoint.split(".")[0]);
                break
            }
        }
        return $sharePointUrl
    }
    catch{
        Write-Debug $_
    }
}


