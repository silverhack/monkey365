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

function Get-MonkeyADALAuthenticationContext {
    <#
     .SYNOPSIS
     Get Authentication context

     .DESCRIPTION
     The Get-MonkeyADALAuthenticationContext function gets you a valid ADAL Authentication Context. If no TenantId or Tenant name is passed
     a "Common" Authentication Context is returned

     .EXAMPLE
     Get-MonkeyADALAuthenticationContext -Login https://login.microsoft.conline.com -TenantID 00000000-0000-0000-0000-000000000000

     This example gets an AuthenticationContext object for the 00000000-0000-0000-0000-000000000000 TenantID.

     .EXAMPLE
     Get-MonkeyADALAuthenticationContext -Login https://login.microsoft.conline.com -TenantID tenant.onmicrosoft.com

     This example gets an AuthenticationContext object for the tenant.onmicrosoft.com .
    #>
    param
    (
        [parameter(Mandatory=$false,HelpMessage = 'Please specify auth login')]
        [String]$Login = "https://login.microsoftonline.com",

        [Parameter(Mandatory=$false,HelpMessage = 'Please specify the Tenant Id or Tenant name')]
        [String]$TenantID


    )
    if($TenantID){
        $AzureAuthority = "{0}/{1}" -f $Login, $TenantID
    }
    else{
        $AzureAuthority = "{0}/{1}" -f $Login, "Common"
    }
    #Create authentication Context
    $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($AzureAuthority)
    if($authContext){
        return $authContext
    }
    else{
        return $null
    }
}
