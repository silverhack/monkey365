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

Function Get-SharepointUrl{
    <#
     .SYNOPSIS
     Get Sharepoint Url from Global Tenant var

     .DESCRIPTION
     The Get-SharepointUrl function lets you get the Sharepoint URL from global Tenant var

     .EXAMPLE
     Get-SharepointUrl

     This example gets sharepoint URL from verifiedDomains var
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
    Try{
        $sharePointUrl = $null
        switch ($Environment) {
            "AzurePublic"
            {
                $sharePointUrl = ("https://{0}.sharepoint.com" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureUSGovernment"
            {
                $sharePointUrl = ("https://{0}.sharepoint.us" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureGermany"
            {
                $sharePointUrl = ("https://{0}.sharepoint.de" -f $Endpoint.split(".")[0]);
                break
            }
            "AzureChina"{
                $sharePointUrl = ("https://{0}.sharepoint.cn" -f $Endpoint.split(".")[0]);
                break
            }
            "Default"
            {
                $sharePointUrl = ("https://{0}.sharepoint.com" -f $Endpoint.split(".")[0]);
                break
            }
        }
        return $sharePointUrl
    }
    Catch{
        Write-Debug $_
    }
}

