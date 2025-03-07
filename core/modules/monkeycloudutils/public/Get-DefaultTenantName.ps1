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

Function Get-DefaultTenantName{
    <#
     .SYNOPSIS
     Get default tenant name from Global Tenant var

     .DESCRIPTION
     The Get-DefaultTenantName function lets you get the tenant DNS name from global Tenant var

     .EXAMPLE
     Get-DefaultTenantName

     This example gets the tenant DNS name from verifiedDomains var
    #>
    [CmdletBinding()]
    param
    (
        # Well Known Azure service
        [Parameter(Mandatory = $false, HelpMessage = 'Tenant details')]
        [Object] $TenantDetails
    )
    try{
        if($null -ne $TenantDetails){
            $defaultDomain = $TenantDetails.verifiedDomains.Where({$_.capabilities -like "*OfficeCommunicationsOnline*" -and $_.isInitial -eq $true})
            if($defaultDomain.Count -gt 0){
                return $defaultDomain[0].name
            }
            else{
                #Write message
                Write-Warning -Message $Script:messages.TenantDNSErrorMessage;
            }
        }
    }
    catch{
        Write-Debug $_
    }
}


