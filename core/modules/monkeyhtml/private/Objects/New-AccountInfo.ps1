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

function New-AccountInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-AccountInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [Parameter(Mandatory=$false, HelpMessage= "Provider")]
        [ValidateSet('Azure','Microsoft365','EntraID')]
        [String]$Instance,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        $AccountInfo = [xml] '<div class="d-flex justify-content-center mb-4" id="accountInfo"><div class="accountId" id="accountId"><i class="" id="Provider"></i><span id="Provider"></span><i class="bi bi-chevron-double-right cloud-monkey-color"></i><span id="AccountName"></span></div></div>'
        #Import node
        $AccountInfo = $TemplateObject.ImportNode($AccountInfo.DocumentElement,$true);
    }
    Process{
        If($null -ne (Get-Variable -Name ExecutionInfo -Scope Script -ErrorAction Ignore)){
            switch($Instance){
                'Azure'{
                    #Select subscription ID
                    $span = $AccountInfo.SelectSingleNode('//span[@id="AccountName"]')
                    $span.InnerText = $Script:ExecutionInfo.subscription.displayName
                    #Add Logo
                    $logo = $AccountInfo.SelectSingleNode('//i[@id="Provider"]')
                    $logo.class = "ms-Icon ms-Icon--AzureIcon cloud-monkey-color"
                    #Set Name
                    $CloudType = $AccountInfo.SelectSingleNode('//span[@id="Provider"]')
                    $CloudType.InnerText = 'Microsoft Azure'
                }
                'Microsoft365'{
                    #Select subscription ID
                    $span = $AccountInfo.SelectSingleNode('//span[@id="AccountName"]')
                    $span.InnerText = $Script:ExecutionInfo.tenant.TenantName
                    #Add Logo
                    $logo = $AccountInfo.SelectSingleNode('//i[@id="Provider"]')
                    $logo.class = "ms-Icon ms-Icon--OfficeLogo cloud-monkey-color"
                    #Set Name
                    $CloudType = $AccountInfo.SelectSingleNode('//span[@id="Provider"]')
                    $CloudType.InnerText = 'Microsoft 365'
                }
                'EntraID'{
                    #Select subscription ID
                    $span = $AccountInfo.SelectSingleNode('//span[@id="AccountName"]')
                    $span.InnerText = $Script:ExecutionInfo.tenant.TenantName
                    #Add Logo
                    $logo = $AccountInfo.SelectSingleNode('//i[@id="Provider"]')
                    $logo.class = "ms-Icon ms-Icon--AADLogo cloud-monkey-color"
                    #Set Name
                    $CloudType = $AccountInfo.SelectSingleNode('//span[@id="Provider"]')
                    $CloudType.InnerText = 'Microsoft Entra ID'
                }
                Default{
                    #Select subscription ID
                    $span = $AccountInfo.SelectSingleNode('//span[@id="AccountName"]')
                    $span.InnerText = $Script:ExecutionInfo.tenant.TenantName
                    #Add Logo
                    $logo = $AccountInfo.SelectSingleNode('//i[@id="Provider"]')
                    $logo.class = "bi bi-cloud cloud-monkey-color"
                    #Set Name
                    $CloudType = $AccountInfo.SelectSingleNode('//span[@id="Provider"]')
                    $CloudType.InnerText = 'Microsoft Azure'
                }
            }
            #Close i tags
            $i = $AccountInfo.SelectNodes("//i")
            #$i | % {$_.InnerText = [string]::Empty}
            $i | ForEach-Object {[void]$_.AppendChild($TemplateObject.CreateWhitespace(""))}
        }
        #Return object
        return $AccountInfo
    }
    End{
        #Nothing to do here
    }
}
