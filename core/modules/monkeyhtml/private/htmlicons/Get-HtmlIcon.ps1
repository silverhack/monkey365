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

Function Get-HtmlIcon{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HtmlIcon
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, HelpMessage="Icon Name")]
        [String]$icon_name
    )
    Begin{
        $all_icons = @{
            'Monkey365'='assets/inc-monkey/logo/MonkeyLogo.png'
            'Active Directory'='assets/inc-azicons/identity/10221-icon-service-Azure-Active-Directory.svg'
            'App Services'='assets/inc-azicons/app services/10035-icon-service-App-Services.svg'
            'Active Directory Identity'='assets/inc-azicons/identity/10230-icon-service-Users.svg'
            'Applications'='assets/inc-azicons/identity/10225-icon-service-Enterprise-Applications.svg'
            'Subscription Policies'='assets/inc-azicons/management + governance/10316-icon-service-Policy.svg'
            'Subscription Identity'='assets/inc-azicons/identity/10235-icon-service-Identity-Governance.svg'
            'Subscription Security'='assets/inc-azicons/general/10002-icon-service-Subscriptions.svg'
            'Azure Subscription'='assets/inc-azicons/general/10002-icon-service-Subscriptions.svg'
            'Azure Defender'='assets/inc-azicons/security/02247-icon-service-Azure-Defender.svg'
            'Azure Log Profile'='assets/inc-azicons/management + governance/00001-icon-service-Monitor.svg'
            'Azure Alerts'='assets/inc-azicons/management + governance/00002-icon-service-Alerts.svg'
            'Azure KeyVault'='assets/inc-azicons/security/10245-icon-service-Key-Vaults.svg'
            'Network Watcher'='assets/inc-azicons/networking/10066-icon-service-Network-Watcher.svg'
            'Azure Disks'='assets/inc-azicons/compute/10032-icon-service-Disks.svg'
            'SQL Server'='assets/inc-azicons/databases/10130-icon-service-SQL-Database.svg'
            'Azure Virtual Machines'='assets/inc-azicons/compute/10021-icon-service-Virtual-Machine.svg'
            'Network Security Groups'='assets/inc-azicons/networking/10067-icon-service-Network-Security-Groups.svg'
            'Storage Accounts'='assets/inc-azicons/storage/10086-icon-service-Storage-Accounts.svg'
            'PostgreSQL Server'='assets/inc-azicons/databases/10131-icon-service-Azure-Database-PostgreSQL-Server.svg'
            'PostgreSQL Configuration'='assets/inc-azicons/databases/10131-icon-service-Azure-Database-PostgreSQL-Server.svg'
            'MySQL Server'='assets/inc-azicons/databases/10122-icon-service-Azure-Database-MySQL-Server.svg'
            'Microsoft 365'='assets/inc-officeicons/64x64/office-365.svg'
            'Sharepoint Online'='assets/inc-officeicons/64x64/Microsoft_Office_SharePoint.svg'
            'Sharepoint Online Identity'='assets/inc-officeicons/64x64/Microsoft_Office_SharePoint.svg'
            'Exchange Online'='assets/inc-officeicons/64x64/Microsoft_Exchange.svg'
            'Microsoft Forms'='assets/inc-officeicons/64x64/Microsoft_Forms.svg'
            'Microsoft Teams'='assets/inc-officeicons/64x64/Microsoft_Office_Teams.svg'
            'Microsoft OneDrive'='assets/inc-officeicons/64x64/Microsoft_Office_OneDrive.svg'
            'Security and Compliance'='assets/inc-officeicons/64x64/microsoft-365-security-&-compliance.svg'
            'Diagnostic Settings'='assets/inc-azicons/management + governance/00008-icon-service-Diagnostics-Settings.svg'
        }
    }
    Process{
        #Try to get icon
        $icon = $all_icons.GetEnumerator() | Where-Object {$_.Name -like ('{0}' -f $icon_name)} | Select-Object -ExpandProperty Value -ErrorAction Ignore
        if($null -eq $icon){
            $icon = 'assets/inc-azicons/general/10001-icon-service-All-Resources.svg'
        }
    }
    End{
        return $icon
    }
}
