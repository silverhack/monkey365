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




Function Get-MonkeyEnvironment{
    <#
        .SYNOPSIS
		Get endpoints
Same as command Get-AzureRmEnvironment
https://docs.microsoft.com/en-us/graph/deployments

        .DESCRIPTION
		Get endpoints
Same as command Get-AzureRmEnvironment
https://docs.microsoft.com/en-us/graph/deployments

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEnvironment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory= $false, HelpMessage= "Select an instance of Azure services")]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic"
    )
    #Export data
    switch ($Environment) {
        'AzurePublic'
        {
            [pscustomobject]$MonkeyEndpoints = @{
                Login = "https://login.microsoftonline.com";
                Graph = "https://graph.windows.net";
                Graphv2 = "https://graph.microsoft.com/";
                ResourceManager = "https://management.azure.com/";
                Outlook = "https://outlook.office365.com/";
                ExchangeOnline = "https://outlook.office365.com/Powershell-LiveId";
                ComplianceCenter = "https://ps.compliance.protection.outlook.com/Powershell-LiveId";
                Lync = "https://admin1e.online.lync.com/OcsPowershellOAuth";
                AADPortal = "https://main.iam.ad.ext.azure.com/api/";
                AADRM = "https://aadrm.com";
                Forms = "https://forms.office.com";
                Storage = "https://storage.azure.com/";
                Vaults = "https://vault.azure.net";
                Servicemanagement = 'https://management.core.windows.net/';
                Security = 'https://s2.security.ext.azure.com/api/';
                LogAnalytics = 'https://api.loganalytics.io/';
                WebAppServicePortal = 'https://web1.appsvcux.ext.azure.com/';
                LegacyO365API = 'https://provisioningapi.microsoftonline.com/provisioningwebservice.svc';
                Teams = 'https://api.interfaces.records.teams.microsoft.com';
                AzurePortal = 'https://portal.azure.com';
            }
        }
        'AzureChina'
        {
            [pscustomobject]$MonkeyEndpoints = @{
                Login = "https://login.chinacloudapi.cn";
                Graph = "https://graph.chinacloudapi.cn";
                Graphv2 = "https://microsoftgraph.chinacloudapi.cn/";
                ResourceManager = "https://management.chinacloudapi.cn/";
                Outlook = "https://outlook.office365.com/";
                ExchangeOnline = "https://outlook.office365.com/powershell-liveid";
                ComplianceCenter = "https://ps.compliance.protection.outlook.com/powershell-liveid";
                Lync = "https://admin1e.online.lync.com/OcsPowershellOAuth";
                AADPortal = "https://main.iam.ad.ext.azure.com/api/";
                AADRM = "https://aadrm.com";
                Forms = "https://forms.office.com";
                Storage = "https://storage.azure.com/";
                Vaults = "https://vault.azure.net";
                Servicemanagement = 'https://management.core.chinacloudapi.cn/';
                Security = 'https://s2.security.ext.azure.com/api/';
                LogAnalytics = 'https://api.loganalytics.io/';
                WebAppServicePortal = 'https://web1.appsvcux.ext.azure.com/';
                LegacyO365API = 'https://provisioningapi.microsoftonline.com/provisioningwebservice.svc';
                Teams = 'https://api.interfaces.records.teams.microsoft.com';
                AzurePortal = 'https://portal.azure.cn';
            }
        }
        'AzureUSGovernment'
        {
            [pscustomobject]$MonkeyEndpoints = @{
                Login = "https://login-us.microsoftonline.com";
                Graph = "https://graph.windows.net";
                Graphv2 = "https://graph.microsoft.us/";
                ResourceManager = "https://management.usgovcloudapi.net/";
                Outlook = "https://outlook.office365.us/";
                ExchangeOnline = "https://outlook.office365.us/powershell-liveid";
                ComplianceCenter = "https://ps.compliance.protection.outlook.us/powershell-liveid";
                Lync = "https://admin1e.online.lync.com/OcsPowershellOAuth";
                AADPortal = "https://main.iam.ad.ext.azure.com/api/";
                AADRM = "https://aadrm.us";
                Forms = "https://forms.office.com";
                Storage = "https://storage.azure.com/";
                Vaults = "https://vault.azure.net";
                Servicemanagement = 'https://management.core.usgovcloudapi.net/';
                Security = 'https://s2.security.ext.azure.com/api/';
                LogAnalytics = 'https://api.loganalytics.io/';
                WebAppServicePortal = 'https://web1.appsvcux.ext.azure.com/';
                LegacyO365API = 'https://provisioningapi.microsoftonline.com/provisioningwebservice.svc';
                Teams = 'https://api.interfaces.records.teams.microsoft.com';
                AzurePortal = 'https://portal.azure.us';
            }
        }
        'AzureGermany'
        {
            [pscustomobject]$MonkeyEndpoints = @{
                Login = "https://login.microsoftonline.de";
                Graph = "https://graph.cloudapi.de";
                Graphv2 = "https://graph.microsoft.de/";
                ResourceManager = "https://management.microsoftazure.de/";
                Outlook = "https://outlook.office365.de/";
                ExchangeOnline = "https://outlook.office365.de/powershell-liveid";
                ComplianceCenter = "https://ps.compliance.protection.outlook.de/powershell-liveid";
                Lync = "https://admin1e.online.lync.com/OcsPowershellOAuth";
                AADPortal = "https://main.iam.ad.ext.azure.com/api/";
                AADRM = "https://aadrm.com";
                Forms = "https://forms.office.com";
                Storage = "https://storage.azure.com/";
                Vaults = "https://vault.azure.net";
                Servicemanagement = 'https://management.core.windows.net/';
                Security = 'https://s2.security.ext.azure.com/api/';
                LogAnalytics = 'https://api.loganalytics.io/';
                WebAppServicePortal = 'https://web1.appsvcux.ext.azure.com/';
                LegacyO365API = 'https://provisioningapi.microsoftonline.com/provisioningwebservice.svc';
                Teams = 'https://api.interfaces.records.teams.microsoft.com';
                AzurePortal = 'https://portal.microsoftazure.de';
            }
        }
        'Default'
        {
            Write-Verbose -Message $script:messages.EndpointNotFound -f $Environment
            exit
        }
    }
    return $MonkeyEndpoints
}





