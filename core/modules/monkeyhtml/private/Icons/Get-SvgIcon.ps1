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

Function Get-SvgIcon{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-SvgIcon
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Icon Name")]
        [String]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Get raw SVG data")]
        [Switch]$Raw
    )
    Begin{
        $all_icons = @{
            'Monkey365'='assets/inc-monkey/logo/MonkeyLogo.png'
            'General'='assets/inc-entraicons/Microsoft_Entra_ID_color_icon.svg'
            'Users'='assets/inc-azicons/identity/10230-icon-service-Users.svg'
            'Groups'='assets/inc-azicons/identity/10223-icon-service-Groups.svg'
            'App Registrations'='assets/inc-azicons/identity/10232-icon-service-App-Registrations.svg'
            'Enterprise Applications'='assets/inc-azicons/identity/10225-icon-service-Enterprise-Applications.svg'
            'Conditional Access'='assets/inc-azicons/security/10233-icon-service-Conditional-Access.svg'
            'App Services'='assets/inc-azicons/app services/10035-icon-service-App-Services.svg'
            'Entra Identity Governance'='assets/inc-azicons/identity/10235-icon-service-Identity-Governance.svg'
            'Identity Protection'='assets/inc-azicons/identity/10231-icon-service-Entra-ID-Protection.svg'
            'Applications'='assets/inc-azicons/identity/10225-icon-service-Enterprise-Applications.svg'
            'Subscription Policies'='assets/inc-azicons/management + governance/10316-icon-service-Policy.svg'
            'Subscription Identity'='assets/inc-azicons/identity/10235-icon-service-Identity-Governance.svg'
            'Subscription Security'='assets/inc-azicons/general/10002-icon-service-Subscriptions.svg'
            'Azure Subscription'='assets/inc-azicons/general/10002-icon-service-Subscriptions.svg'
            'Defender for Cloud'='assets/inc-azicons/security/10241-icon-service-Microsoft-Defender-for-Cloud.svg'
            'Azure Log Profile'='assets/inc-azicons/management + governance/00001-icon-service-Monitor.svg'
            'Azure Alerts'='assets/inc-azicons/management + governance/00002-icon-service-Alerts.svg'
            'Azure KeyVault'='assets/inc-azicons/security/10245-icon-service-Key-Vaults.svg'
            'Bastion'='assets/inc-azicons/networking/02422-icon-service-Bastions.svg'
            'Network Watcher'='assets/inc-azicons/networking/10066-icon-service-Network-Watcher.svg'
            'Azure Disks'='assets/inc-azicons/compute/10032-icon-service-Disks.svg'
            'SQL Server'='assets/inc-azicons/databases/10130-icon-service-SQL-Database.svg'
            'Azure Virtual Machines'='assets/inc-azicons/compute/10021-icon-service-Virtual-Machine.svg'
            'Network Security Groups'='assets/inc-azicons/networking/10067-icon-service-Network-Security-Groups.svg'
            'Storage Accounts'='assets/inc-azicons/storage/10086-icon-service-Storage-Accounts.svg'
            'PostgreSQL Server'='assets/inc-azicons/databases/10131-icon-service-Azure-Database-PostgreSQL-Server.svg'
            'PostgreSQL Configuration'='assets/inc-azicons/databases/10131-icon-service-Azure-Database-PostgreSQL-Server.svg'
            'MySQL Configuration'='assets/inc-azicons/databases/10122-icon-service-Azure-Database-MySQL-Server.svg'
            'MySQL Server'='assets/inc-azicons/databases/10122-icon-service-Azure-Database-MySQL-Server.svg'
            'Microsoft 365'='assets/inc-officeicons/64x64/office-365.svg'
            'Sharepoint Online'='assets/inc-officeicons/64x64/Microsoft_Office_SharePoint.svg'
            'Sharepoint Online Identity'='assets/inc-officeicons/64x64/Microsoft_Office_SharePoint.svg'
            'Exchange Online'='assets/inc-officeicons/64x64/Microsoft_Exchange.svg'
            'Microsoft Forms'='assets/inc-officeicons/64x64/Microsoft_Forms.svg'
            'Microsoft Teams'='assets/inc-officeicons/64x64/Microsoft_Office_Teams.svg'
            'Microsoft OneDrive'='assets/inc-officeicons/64x64/Microsoft_Office_OneDrive.svg'
            'Security and Compliance'='assets/inc-officeicons/64x64/microsoft-365-security-&-compliance.svg'
            'Purview'='assets/inc-officeicons/64x64/Microsoft_Purview.svg'
            'Fabric'='assets/inc-officeicons/48x48/fabric_48_color.svg'
            'Microsoft 365 Admin'='assets/inc-officeicons/48x48/m365_admin.svg'
            'Diagnostic Settings'='assets/inc-azicons/management + governance/00008-icon-service-Diagnostics-Settings.svg'
            'Public Ip Addresses'='assets/inc-azicons/networking/10069-icon-service-Public-IP-Addresses.svg'
            'Application Insights'='assets/inc-azicons/monitor/00012-icon-service-Application-Insights.svg'
        }
        #Set null
        $_iconPath = $null;
    }
    Process{
        Try{
            #Try to get icon
            $icon = $all_icons.GetEnumerator() | Where-Object {$_.Name -like ('{0}' -f $InputObject)} | Select-Object -ExpandProperty Value -ErrorAction Ignore
            If($null -eq $icon){
                $icon = 'assets/inc-azicons/general/10001-icon-service-All-Resources.svg'
            }
            If($Script:mode -eq 'cdn' -or $Script:mode -eq 'localcdn'){
                $baseUrl = ("{0}/{1}" -f $Script:Repository,$icon);
                If($Script:mode -eq 'cdn'){
                    $_iconPath = Convert-UrlToJsDelivr -Url $baseUrl -Latest
                }
                Else{
                    $_iconPath = $baseUrl;
                }
                If($PSBoundParameters.ContainsKey('Raw') -and $PSBoundParameters['Raw'].IsPresent){
                    Try{
                        $content = Invoke-WebRequest -Uri $_iconPath -UseBasicParsing
                        $streamReader = [System.IO.StreamReader]::new($content.RawContentStream,[System.Text.Encoding]::UTF8);
                        [xml]$iconXml = $streamReader.ReadToEnd();
                        $streamReader.Close();
                        return $iconXml
                    }
                    Catch{
                        Write-Warning ($Script:messages.FileNotFoundErrorMessage -f $_iconPath)
                        Write-Error $_.Exception
                    }
                }
                Else{
                    return $_iconPath
                }
            }
            Else{
                $_iconPath = ("{0}/{1}" -f $Script:LocalPath,$icon);
                If($PSBoundParameters.ContainsKey('Raw') -and $PSBoundParameters['Raw'].IsPresent){
                    If([System.IO.File]::Exists($_iconPath)){
                        $streamReader = [System.IO.StreamReader]::new($_iconPath,[System.Text.Encoding]::UTF8);
                        [xml]$iconXml = $streamReader.ReadToEnd();
                        $streamReader.Close();
                        return $iconXml
                    }
                    Else{
                        Write-Warning ($Script:messages.FileNotFoundErrorMessage -f $_iconPath)
                    }
                }
                Else{
                    return $_iconPath
                }
            }
        }
        Catch{
            Write-Error $_
        }
    }
    End{
        #Nothing to do here
    }
}
