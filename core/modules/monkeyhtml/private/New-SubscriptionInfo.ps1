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

function New-SubscriptionInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-SubscriptionInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [Parameter(Mandatory=$false)]
        [ValidateSet('Azure','Microsoft365','EntraID')]
        [String]$Instance
    )
    Begin{
        $sub_info = [xml] '<div class="d-flex justify-content-center mb-4" id="flavor"><h4><div class="list-group-item-text std-size"><span id="account_id"><i class="ms-Icon ms-Icon--AzureIcon cloud-monkey-color fa-lg" id="cloudType"/><span class="azure" id="cloudType">Microsoft Azure</span><i class="bi bi-chevron-double-right cloud-monkey-color"/><span class="subscription"/></span></div></h4></div>'
    }
    Process{
        switch($Instance){
            'Azure'{
                #Select subscription ID
                $span = $sub_info.SelectSingleNode('//span[@class="subscription"]')
                $span.InnerText = $script:user_info.subscription.displayName
                #Add Logo
                $logo = $sub_info.SelectSingleNode('//i[@id="cloudType"]')
                $logo.class = "ms-Icon ms-Icon--AzureIcon cloud-monkey-color fa-lg"
                #Set Name
                $CloudType = $sub_info.SelectSingleNode('//span[@id="cloudType"]')
                $CloudType.InnerText = 'Microsoft Azure'
            }
            'Microsoft365'{
                #Select subscription ID
                $span = $sub_info.SelectSingleNode('//span[@class="subscription"]')
                $span.InnerText = $script:user_info.tenant.TenantName
                #Add Logo
                $logo = $sub_info.SelectSingleNode('//i[@id="cloudType"]')
                $logo.class = "ms-Icon ms-Icon--OfficeLogo cloud-monkey-color fa-lg"
                #Set Name
                $CloudType = $sub_info.SelectSingleNode('//span[@id="cloudType"]')
                $CloudType.InnerText = 'Microsoft 365'
            }
            'EntraID'{
                #Select subscription ID
                $span = $sub_info.SelectSingleNode('//span[@class="subscription"]')
                $span.InnerText = $script:user_info.tenant.TenantName
                #Add Logo
                $logo = $sub_info.SelectSingleNode('//i[@id="cloudType"]')
                $logo.class = "ms-Icon ms-Icon--AADLogo cloud-monkey-color fa-lg"
                #Set Name
                $CloudType = $sub_info.SelectSingleNode('//span[@id="cloudType"]')
                $CloudType.InnerText = 'Microsoft Entra ID'
            }
            Default{
                #Select subscription ID
                $span = $sub_info.SelectSingleNode('//span[@class="subscription"]')
                $span.InnerText = $script:user_info.tenant.TenantName
                #Add Logo
                $logo = $sub_info.SelectSingleNode('//i[@id="cloudType"]')
                $logo.class = "bi bi-cloud cloud-monkey-color"
                #Set Name
                $CloudType = $sub_info.SelectSingleNode('//span[@id="cloudType"]')
                $CloudType.InnerText = 'Microsoft Azure'
            }
        }
        #Close i tags
        $i = $sub_info.SelectNodes("//i")
        #$i | % {$_.InnerText = [string]::Empty}
        $i | ForEach-Object {[void]$_.AppendChild($sub_info.CreateWhitespace(""))}
    }
    End{
        return $sub_info
    }
}

