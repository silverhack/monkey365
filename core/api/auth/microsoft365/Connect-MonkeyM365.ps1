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

Function Connect-MonkeyM365{
    <#
        .SYNOPSIS
        Connect to Microsoft 365 services

        .DESCRIPTION
        Connect to Microsoft 365 services

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyM365
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    foreach ($service in $O365Object.initParams.Analysis){
        switch ($service.ToLower()) {
            #Connect to Exchange Online
            'exchangeonline'{
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Exchange Online")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                $O365Object.auth_tokens.ExchangeOnline = Get-TokenForEXO
                if($null -ne $O365Object.auth_tokens.ExchangeOnline){
                    #Get ExchangeOnline module file
                    $p = @{
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $moduleFile = Get-PSExoModuleFile @p
                    if($moduleFile){
                        $O365Object.onlineServices.Item($service) = $true
                    }
                    else{
                        $msg = @{
                            MessageData = ($message.NotConnectedTo -f $service);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365ExchangeOnlineError');
                        }
                        Write-Warning @msg
                    }
                }
            }
            #Connect to Microsoft Purview
            'purview'{
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Microsoft Purview")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                #Add resource for ComplianceCenter
                $O365Object.auth_tokens.ComplianceCenter = Get-TokenForEXO
                #Get Backend URI
                if($null -ne $O365Object.auth_tokens.ComplianceCenter){
                    #Update TenantId in Compliance Center Auth token
                    $tid = Read-JWTtoken -token $O365Object.auth_tokens.ComplianceCenter.AccessToken | Select-Object -ExpandProperty tid -ErrorAction Ignore
                    $O365Object.auth_tokens.ComplianceCenter | Add-Member -type NoteProperty -name TenantId -value $tid -Force
                    $O365Object.SecCompBackendUri = Get-MonkeySecCompBackendUri
                    if($null -ne $O365Object.SecCompBackendUri){
                        #Get ExchangeOnline module file
                        $p = @{
                            Purview = $true;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $moduleFile = Get-PSExoModuleFile @p
                        if($moduleFile){
                            $O365Object.onlineServices.Item($service) = $true
                        }
                        else{
                            $msg = @{
                                MessageData = ($message.NotConnectedTo -f $service);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'warning';
                                InformationAction = $O365Object.InformationAction;
                                Tags = @('Monkey365PurviewError');
                            }
                            Write-Warning @msg
                        }
                    }
                    else{
                        $msg = @{
                            MessageData = "Unable to get Security and Compliance backend Uri";
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365PurviewError');
                        }
                        Write-Warning @msg;
                        $msg = @{
                            MessageData = ($message.NotConnectedTo -f $service);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365PurviewError');
                        }
                        Write-Warning @msg;
                    }
                }
            }
            #Connect to SharePoint Online
            'sharepointonline'{
                if($O365Object.AuthType.ToLower() -eq 'client_credentials'){
                    $msg = @{
                        MessageData = ($message.SPSConfidentialAppErrorMessage);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365ConfidentialAppSPOError');
                    }
                    Write-Warning @msg
                    #Set sharepoint admin flag
                    $O365Object.isSharePointAdministrator = $false
                    $O365Object.onlineServices.Item($service) = $false
                    $msg = @{
                        MessageData = ($message.NotConnectedTo -f $service);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365SharePointError');
                    }
                    Write-Warning @msg
                    continue;
                }
                #Set null
                $initialDomain = $null;
                #Get initial domain
                If($O365Object.isValidTenantGuid -eq $false){
                    $initialDomain = $O365Object.TenantId
                }
                Elseif($O365Object.initParams.ContainsKey('ScanSites') -and @($O365Object.initParams.ScanSites).Count -gt 0){
                    [uri]$dnsName = $O365Object.initParams.ScanSites | Select-Object -First 1
                    $initialDomain = ("{0}" -f $dnsName.DnsSafeHost)
                }
                ElseIf($null -ne $O365Object.Tenant.CompanyInfo){
                    $initialDomain = $O365Object.Tenant.CompanyInfo.verifiedDomains.Where({$_.capabilities -like "*OfficeCommunicationsOnline*" -and $_.isDefault -eq $true}) | Select-Object -ExpandProperty name
                }
                If($null -eq $initialDomain){
                    $msg = @{
                        MessageData = ($message.NotConnectedTo -f $service);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365SharePointError');
                    }
                    Write-Warning @msg
                    $msg = @{
                        MessageData = "Unable to connect SharePoint online. No valid host was found";
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365SharePointError');
                    }
                    Write-Warning @msg
                    return
                }
                #Connect to root site
                $p = @{
                    Endpoint = $initialDomain;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "SharePoint Online")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                $O365Object.auth_tokens.SharePointOnline = Connect-MonkeySPO @p -RootSite
                #Connect to the admin site
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "SharePoint Online admin")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                $O365Object.auth_tokens.SharePointAdminOnline = Connect-MonkeySPO @p -Admin
                #Connect to OneDrive site
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "OneDrive For Business")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                $O365Object.auth_tokens.OneDrive = Connect-MonkeySPO @p -OneDrive
                if($null -ne $O365Object.auth_tokens.SharePointOnline -and $null -ne $O365Object.auth_tokens.SharePointAdminOnline){
                    #Check if user is SharePoint administrator
                    $p = @{
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $O365Object.isSharePointAdministrator = Test-IsUserSharepointAdministrator @p
                    if($O365Object.isSharePointAdministrator -eq $false){
                        $msg = @{
                            MessageData = ($message.NotConnectedTo -f "SharePoint Online admin site");
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365SharePointError');
                        }
                        Write-Warning @msg
                    }
                    #Get config
                    try{
                        $scanSites = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.sitePermissionsOptions.scanAllSites)
                    }
                    catch{
                        $msg = @{
                            MessageData = ($message.MonkeyInternalConfigError);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365ConfigError');
                        }
                        Write-Verbose @msg
                        #Set scanSites to false
                        $scanSites = $false
                    }
                    #Check if ScanSites
                    if($O365Object.initParams.ContainsKey('ScanSites') -and @($O365Object.initParams.ScanSites).Count -gt 0){
                        $p = @{
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        #Execute command
                        $O365Object.spoSites = ($O365Object.initParams.ScanSites.GetEnumerator() | ForEach-Object {Get-MonkeyCSOMSite @p -Endpoint $_}) | Sort-Object -Unique -Property Url
                    }
                    else{
                        $p = @{
                            All = $scanSites;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        #Get Webs for user
                        $O365Object.spoSites = Get-MonkeyCSOMSite @p
                    }
                    if($null -ne $O365Object.spoSites){
                        $O365Object.onlineServices.Item($service) = $true
                    }
                    else{
                        $msg = @{
                            MessageData = ($message.NotConnectedTo -f $service);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365SharePointError');
                        }
                        Write-Warning @msg
                    }
                }
            }
            #Connect to Microsoft Teams
            'microsoftteams'{
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Microsoft Teams")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                $p = @{
                    Resource = (Get-WellKnownAzureService -AzureService TeamsAdminApi);
                    AzureService = "AzurePowershell";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $O365Object.auth_tokens.Teams = Connect-MonkeyGenericApplication @p
                #$O365Object.auth_tokens.Teams = Connect-MonkeyTeamsForOffice
                if($null -ne $O365Object.auth_tokens.Teams){
                    #Get Backend URI
                    $p = @{
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $backend = Get-MonkeyTeamsServiceDiscovery @p
                    if($backend -and $null -ne $backend.Psobject.Properties.Item('Endpoints')){
                        $O365Object.Environment.Teams = ("https://{0}" -f $backend.Endpoints.ConfigApiEndpoint)
                    }
                    #Test if connection to Teams is allowed
                    $p = @{
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $isConnected = Test-TeamsConnection @p
                    if($isConnected){
                        $O365Object.onlineServices.Item($service) = $true
                    }
                    else{
                        $msg = @{
                            MessageData = ($message.NotConnectedTo -f $service);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365TeamsError');
                        }
                        Write-Warning @msg
                    }
                }
            }
            #Connect to Microsoft365
            'microsoft365'{
                if($O365Object.AuthType.ToLower() -eq 'client_credentials' -or $O365Object.AuthType.ToLower() -eq 'certificate_credentials'){
                    $msg = @{
                        MessageData = ($message.SPNotAllowedAuthFlowErrorMessage -f "Microsoft 365 Admin portal");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365AdminPortalError');
                    }
                    Write-Warning @msg
                    $msg = @{
                        MessageData = ($message.NotConnectedTo -f $service);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365AdminPortalError');
                    }
                    Write-Warning @msg
                    continue;
                }
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Microsoft Forms")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                #Connect to Microsoft Forms
                $p = @{
                    Resource = (Get-WellKnownAzureService -AzureService MicrosoftForms);
                    AzureService = "AzurePowershell";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $O365Object.auth_tokens.Forms = Connect-MonkeyGenericApplication @p
                #$O365Object.auth_tokens.Forms = Connect-MonkeyFormsForOffice
                if($null -ne $O365Object.auth_tokens.Forms){
                    $O365Object.onlineServices.Item($service) = $true
                }
                Start-Sleep -Milliseconds 10
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Microsoft Right Management Services")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                #Connect to Microsoft Rights Management Services
                $p = @{
                    Resource = $O365Object.Environment.AADRM;
                    AzureService = "AzurePowershell";
                    RedirectUri = "https://aadrm.com/adminpowershell";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $O365Object.auth_tokens.AADRM = Connect-MonkeyGenericApplication @p
                #$O365Object.auth_tokens.AADRM = Connect-MonkeyAADRM
                if($null -ne $O365Object.auth_tokens.AADRM){
                    #Get Service locator url
                    $service_locator = Get-AADRMServiceLocatorUrl
                    #set internal object
                    if($O365Object.Environment.ContainsKey('aadrm_service_locator')){
                        $O365Object.Environment.aadrm_service_locator = $service_locator;
                    }
                    else{
                        $O365Object.Environment.Add('aadrm_service_locator',$service_locator)
                    }
                    $O365Object.onlineServices.Item($service) = $true
                }
                Start-Sleep -Milliseconds 10
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Microsoft 365 Admin Portal")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                #Connect to Admin blade
                $p = @{
                    Resource = $O365Object.Environment.OfficeAdminPortal;
                    AzureService = "AzurePowershell";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $O365Object.auth_tokens.M365Admin = Connect-MonkeyGenericApplication @p
                #$O365Object.auth_tokens.M365Admin = Connect-MonkeyM365AdminPortal
                if($null -ne $O365Object.auth_tokens.M365Admin){
                    #Test if connection to Admin blade is allowed
                    $p = @{
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $isConnected = Test-M365PortalConnection @p
                    if($isConnected){
                        $O365Object.onlineServices.Item($service) = $true
                    }
                    else{
                        $msg = @{
                            MessageData = ($message.NotConnectedTo -f $service);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365AdminPortalError');
                        }
                        Write-Warning @msg
                    }
                }
            }
            #Connect to PowerBI
            'powerbi'{
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Microsoft PowerBI")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                #Connect to PowerBI
                $p = @{
                    Resource = $O365Object.Environment.PowerBI;
                    AzureService = "AzurePowershell";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $O365Object.auth_tokens.PowerBI = Connect-MonkeyGenericApplication @p
                #$O365Object.auth_tokens.PowerBI = Connect-MonkeyPowerBI
                if($null -ne $O365Object.auth_tokens.PowerBI){
                    #Get Backend URI
                    $O365Object.PowerBIBackendUri = Get-MonkeyPowerBIBackendUri
                    if($null -ne $O365Object.PowerBIBackendUri){
                        $O365Object.onlineServices.Item($service) = $true
                    }
                    else{
                        $msg = @{
                            MessageData = ($message.NotConnectedTo -f $service);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365TeamsError');
                        }
                        Write-Warning @msg
                    }
                }
            }
            #Connect to Microsoft Intune
            'intune'{
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Microsoft Intune")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                $p = @{
                    Resource = $O365Object.Environment.Graphv2;
                    AzureService = "Intune";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $O365Object.auth_tokens.Intune = Connect-MonkeyGenericApplication @p
                #$O365Object.auth_tokens.Intune = Connect-MonkeyIntune
                if($null -ne $O365Object.auth_tokens.Intune){
                    $O365Object.onlineServices.Item($service) = $true
                }
            }
        }
    }
    #Get License information
    $O365Object.ATPEnabled = Get-M365ATPLicense
}