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
    Param (
        [Parameter(Mandatory=$true, HelpMessage="parameters")]
        [Object]$parameters
    )
    foreach ($service in $O365Object.initParams.Analysis){
        switch ($service.ToLower()) {
            #Connect to Exchange Online
            'exchangeonline'{
                #$O365Object.o365_sessions.ExchangeOnline = (Connect-MonkeyExchangeOnline -parameters $parameters)
                $O365Object.auth_tokens.ExchangeOnline = (Get-TokenForEXO -parameters $parameters)
                if($null -ne $O365Object.auth_tokens.ExchangeOnline){
                    #Get ExchangeOnline module file
                    $p = @{
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $moduleFile = Get-PSExoModuleFile @p
                    if($moduleFile){
                        $O365Object.onlineServices.$($service) = $True
                    }
                }
            }
            #Connect to Microsoft Purview
            'purview'{
                $O365Object.o365_sessions.ComplianceCenter = (Connect-MonkeyComplianceCenter -parameters $parameters)
                #Add resource for ComplianceCenter
                if($null -ne $O365Object.o365_sessions.ComplianceCenter){
                    $O365Object.auth_tokens.ComplianceCenter = (Get-TokenForEXO -parameters $parameters)
                }
                if($null -ne $O365Object.o365_sessions.ComplianceCenter -and $null -ne $O365Object.auth_tokens.ComplianceCenter){
                    $O365Object.onlineServices.$($service) = $True
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
                    $O365Object.onlineServices.$($service) = $false
                    continue;
                }
                #Set new application args
                $sps_params = @{}
                foreach($elem in $parameters.GetEnumerator()){
                    [void]$sps_params.Add($elem.Key,$elem.Value)
                }
                #Connect to root site
                $sps_params.Add('rootSite',$true);
                $O365Object.auth_tokens.SharePointOnline = (Connect-MonkeySharepointOnline -parameters $sps_params)
                #Set new application args
                $sps_params = @{}
                foreach($elem in $parameters.GetEnumerator()){
                    [void]$sps_params.Add($elem.Key,$elem.Value)
                }
                #Connect to the admin site
                $sps_params.Add('Admin',$true);
                $O365Object.auth_tokens.SharePointAdminOnline = (Connect-MonkeySharepointOnline -parameters $sps_params)
                #Set new application args
                $sps_params = @{}
                foreach($elem in $parameters.GetEnumerator()){
                    [void]$sps_params.Add($elem.Key,$elem.Value)
                }
                #Connects to OneDrive site
                $sps_params.Add('oneDrive',$true);
                $O365Object.auth_tokens.OneDrive = (Connect-MonkeySharepointOnline -parameters $sps_params)
                if($null -ne $O365Object.auth_tokens.SharePointOnline -and $null -ne $O365Object.auth_tokens.SharePointAdminOnline){
                    #Check if user is SharePoint administrator
                    $p = @{
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $O365Object.isSharePointAdministrator = Test-IsUserSharepointAdministrator @p
                    #Get config
                    try{
                        $scanSites = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.ScanSites)
                        $recurseScan = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.Subsites.Recursive)
                        $depthScan = $O365Object.internal_config.o365.SharePointOnline.Subsites.Depth
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
                        $recurseScan = $false
                        $depthScan = 1
                    }
                    #Check if ScanSites
                    if($O365Object.initParams.ContainsKey('ScanSites') -and $O365Object.initParams.ScanSites.Count -gt 0){
                        $p = @{
                            Sites = $O365Object.initParams.ScanSites;
                            Recurse = $recurseScan;
                            Limit = $depthScan;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                    }
                    else{
                        $p = @{
                            ScanSites = $scanSites;
                            Recurse = $recurseScan;
                            Limit = $depthScan;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                    }
                    #Get Webs for user
                    $O365Object.spoWebs = Get-MonkeyCSOMWebsForUser @p
                    $O365Object.onlineServices.$($service) = $True
                }
            }
            #Connect to Microsoft Teams
            'microsoftteams'{
                $O365Object.auth_tokens.Teams = (Connect-MonkeyTeamsForOffice -parameters $parameters)
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
                    $O365Object.onlineServices.$($service) = $True
                }
            }
            #Connect to Microsoft365
            'microsoft365'{
                #Connect to Microsoft Forms
                $O365Object.auth_tokens.Forms = (Connect-MonkeyFormsForOffice -parameters $parameters)
                if($null -ne $O365Object.auth_tokens.Forms){
                    $O365Object.onlineServices.$($service) = $True
                }
                Start-Sleep -Milliseconds 10
                #Connect to Microsoft Rights Management Services
                $O365Object.auth_tokens.AADRM = (Connect-MonkeyAADRM -parameters $parameters)
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
                    $O365Object.onlineServices.$($service) = $True
                }
                Start-Sleep -Milliseconds 10
                #Connect to Admin blade
                $O365Object.auth_tokens.M365Admin = (Connect-MonkeyM365AdminPortal -parameters $parameters)
                if($null -ne $O365Object.auth_tokens.M365Admin){
                    $O365Object.onlineServices.$($service) = $True
                }
            }
            #Connect to PowerBI
            'powerbi'{
                $O365Object.auth_tokens.PowerBI = (Connect-MonkeyPowerBI -parameters $parameters)
                if($null -ne $O365Object.auth_tokens.PowerBI){
                    $O365Object.onlineServices.$($service) = $True
                    #Get Backend URI
                    $O365Object.PowerBIBackendUri = Get-MonkeyPowerBIBackendUri
                }
            }
            #Connect to Microsoft Intune
            'intune'{
                $O365Object.auth_tokens.Intune = (Connect-MonkeyIntune -parameters $parameters)
                if($null -ne $O365Object.auth_tokens.Intune){
                    $O365Object.onlineServices.$($service) = $True
                }
            }
        }
    }
    #Get License information
    $O365Object.ATPEnabled = Get-M365ATPLicense
}