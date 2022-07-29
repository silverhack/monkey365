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

Function Connect-MonkeyCloud{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyCloud
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, HelpMessage= "Silent authentication")]
        [switch]$Silent
    )
    #Connect to Graph
    $app_params = $O365Object.application_args
    if($O365Object.isUsingAdalLib){
        if($O365Object.application_args.ContainsKey('Silent') -and $O365Object.application_args.Silent){
            #Add silent auth if not exists
            if(-NOT $app_params.ContainsKey('Silent')){
                #Add silent auth
                [ref]$null = $app_params.Add('Silent',$true)
            }
        }
        if($PSBoundParameters.ContainsKey('Silent') -and $Silent){
            #Add silent auth
            if(-NOT $app_params.ContainsKey('Silent')){
                #Add silent auth
                [ref]$null = $app_params.Add('Silent',$true)
            }
        }
        #Connect to ResourceManager
        $Script:o365_connections.ResourceManager = (Connect-MonkeyResourceManagement $app_params)
        if($null -ne $Script:o365_connections.ResourceManager){
            #Set TenantId if not exists
            if(-NOT $app_params.ContainsKey('TenantId')){
                [ref]$null = $app_params.Add('TenantId',$Script:o365_connections.ResourceManager.TenantId)
            }
            #remove devicecode
            if($app_params.ContainsKey('DeviceCode')){
                [ref]$null = $app_params.Remove('DeviceCode')
            }
            #Get authentication context
            $O365Object.authContext = Get-MonkeyADALAuthenticationContext -TenantID $app_params.TenantId
            #Add authContext to params
            if(-NOT $app_params.ContainsKey('AuthContext')){
                [ref]$null = $app_params.Add('AuthContext',$O365Object.authContext)
            }
            else{
                $app_params.AuthContext = $O365Object.authContext
            }
            #Add silent auth
            if(-NOT $app_params.ContainsKey('Silent')){
                #Add silent auth
                [ref]$null = $app_params.Add('Silent',$true)
            }
        }
        else{
            #Probably cancelled connection
            return
        }
    }
    else{
        #Using MSAL authentication
        if($null -ne $O365Object.msalapplication -and $null -ne $O365Object.msal_application_args){
            $app_params = $O365Object.msal_application_args
            if($O365Object.msalapplication.isPublicApp){
                #Set parameters
                [ref]$null = $app_params.Add('publicApp',$O365Object.msalapplication);
                if($O365Object.application_args.ContainsKey('Silent') -and $O365Object.application_args.Silent){
                    #Add silent auth if not exists
                    if(-NOT $app_params.ContainsKey('Silent')){
                        #Add silent auth
                        [ref]$null = $app_params.Add('Silent',$true)
                    }
                }
            }
            else{
                #Confidential App
                [ref]$null = $app_params.Add('confidentialApp',$O365Object.msalapplication);
            }
            #Remove ClientId
            if($app_params.ContainsKey('ClientId')){
                [ref]$null = $app_params.Remove('ClientId')
            }
            $Script:o365_connections.ResourceManager = (Connect-MonkeyResourceManagement $app_params)
            if($null -ne $Script:o365_connections.ResourceManager){
                #remove devicecode
                if($app_params.ContainsKey('DeviceCode')){
                    [ref]$null = $app_params.Remove('DeviceCode')
                }
                if(-NOT $app_params.ContainsKey('Silent')){
                    #Add silent auth
                    [ref]$null = $app_params.Add('Silent',$true)
                }
            }
            else{
                #Probably cancelled connection
                return
            }
        }
    }
    #Check if connected
    if($null -ne $Script:o365_connections.ResourceManager){
        $msg = @{
            MessageData = $message.SuccessfullyConnected;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $script:InformationAction;
            Tags = @('SuccessFullyConnected');
        }
        Write-Information @msg
        #Set O365 connection to True
        $Script:OnlineServices.O365 = $True
    }
    #Select tenant
    if($Script:OnlineServices.O365 -eq $true -and $null -eq $O365Object.TenantId){
        $reconnect = Select-MonkeyTenant
        #If reconnect is true, then a new tenant was selected by the user
        if($reconnect){return}
    }
    #Get token from MS Graph
    $Script:o365_connections.Graph = (Connect-MonkeyGraph $app_params)
    #Connect to MSGraph
    $Script:o365_connections.MSGraph = (Connect-MonkeyMSGraph $app_params)
    #Connect to Azure Portal
    $Script:o365_connections.AzurePortal = (Connect-MonkeyAzurePortal $app_params)
    #Get Tenant Information
    $O365Object.auth_tokens = $Script:o365_connections
    $O365Object.Tenant = Get-TenantInformation
    #Check if Azure services is selected
    if($O365Object.initParams.Instance -eq "Azure"){
        #Reconnect to Azure Resource Management
        $Script:o365_connections.ResourceManager = (Connect-MonkeyResourceManagement $app_params)
        if($null -ne $Script:o365_connections.ResourceManager){
            $O365Object.subscriptions = Select-MonkeyAzureSubscription
        }
        if($null -ne $O365Object.subscriptions){
            #Reconnect to all Azure services
            #$param.TenantId = $O365Object.TenantId
            #Connect to Azure
            Connect-MonkeyAzure -parameters $app_params
        }
        else{
            #Probably cancelled operation or user is not assigned to any subscriptions
            return
        }
    }
    #Check if Microsoft 365 is selected
    elseif($O365Object.initParams.Instance -eq "Office365"){
        $count = 0
        foreach ($service in $O365Object.initParams.Analysis){
            switch ($service.ToLower()) {
                { @("exchangeonline", "purview") -contains $_ }{
                    if($count -eq 0){
                        $Script:o365_sessions.ExchangeOnline = (Connect-MonkeyExchangeOnline -parameters $app_params)
                        if($null -ne $Script:o365_sessions.ExchangeOnline){
                            $Script:o365_connections.ExchangeOnline = (Get-TokenForEXO -parameters $app_params)
                        }
                        if($null -ne $Script:o365_sessions.ExchangeOnline -and $null -ne $Script:o365_connections.ExchangeOnline){
                            $Script:OnlineServices.EXO = $True
                        }
                        #Connect to Compliance Center
                        $Script:o365_sessions.ComplianceCenter = (Connect-MonkeyComplianceCenter -parameters $app_params)
                        #Add resource for ComplianceCenter
                        if($null -ne $Script:o365_sessions.ComplianceCenter){
                            $Script:o365_connections.ComplianceCenter = (Get-TokenForEXO -parameters $app_params)
                        }
                        if($null -ne $Script:o365_sessions.ComplianceCenter -and $null -ne $Script:o365_connections.ComplianceCenter){
                            $Script:OnlineServices.Compliance = $True
                        }
                    }
                    $count+=1
                }
                'sharepointonline'{
                    #Connect to root site
                    $sps_params = $app_params.Clone()
                    $sps_params.Add('rootSite',$true);
                    $Script:o365_connections.SharepointOnline = (Connect-MonkeySharepointOnline -parameters $sps_params)
                    #Connect to the admin site
                    $sps_params = $app_params.Clone()
                    $sps_params.Add('Admin',$true);
                    $Script:o365_connections.SharepointAdminOnline = (Connect-MonkeySharepointOnline -parameters $sps_params)
                    #Connects to OneDrive site
                    $sps_params = $app_params.Clone()
                    $sps_params.Add('oneDrive',$true);
                    $Script:o365_connections.OneDrive = (Connect-MonkeySharepointOnline -parameters $sps_params)
                    if($null -ne $Script:o365_connections.SharepointOnline){
                        $Script:OnlineServices.SPS = $True
                    }
                }
                'microsoftteams'{
                    $Script:o365_connections.Teams = (Connect-MonkeyTeamsForOffice -parameters $app_params)
                    if($null -ne $Script:o365_connections.Teams){
                        $Script:OnlineServices.Teams = $True
                    }
                }
                'microsoftforms'{
                    $Script:o365_connections.Forms = (Connect-MonkeyFormsForOffice -parameters $app_params)
                    if($null -ne $Script:o365_connections.Forms){
                        $Script:OnlineServices.Forms = $True
                    }
                }
                'irm'{
                    $Script:o365_connections.AADRM = (Connect-MonkeyAADRM -parameters $app_params)
                    if($null -ne $Script:o365_connections.AADRM){
                        #Get Service locator url
                        $service_locator = Get-AADRMServiceLocatorUrl
                        #set internal object
                        $O365Object.Environment.Add('aadrm_service_locator',$service_locator)
                        $Script:OnlineServices.AADRM = $True
                    }
                }
                'intune'{
                    $Script:o365_connections.Intune = (Connect-MonkeyIntune -parameters $app_params)
                    if($null -ne $Script:o365_connections.Intune){
                        $Script:OnlineServices.Intune = $True
                    }
                }
            }
        }
    }
    #Update object
    $O365Object.AuthType = $Script:o365_connections.Values.GetEnumerator() | Select-Object -ExpandProperty AuthType -Unique -ErrorAction Ignore
    $O365Object.o365_sessions = $Script:o365_sessions
    $O365Object.OnlineServices = $Script:OnlineServices
    #$O365Object.userPrincipalName = $Script:userPrincipalName
    if($O365Object.initParams.Instance -eq "Office365"){
        $O365Object.ATPEnabled = Get-O365ATPLicense
    }
    $O365Object.Licensing = Get-O365LicenseSKU
    $O365Object.userId = Get-MonkeyAzUserId
    #Get Plugins
    $O365Object.Plugins = Get-MonkeyPlugin
    <#
    #Check if EXO connected
    if($Script:OnlineServices.EXO -eq $true -and $null -ne $Script:o365_connections.ExchangeOnline){
        #Get a new PsSession
        $psSession = $null
        $tenantName = $O365Object.Tenant.MyDomain.Id
        $p = @{
            Authentication = $Script:o365_connections.ExchangeOnline;
            userPrincipalName = ("MonkeyUser@{0}" -f $tenantName);
            resource = $O365Object.Environment.ExchangeOnline;
        }
        $psSession = New-O365PsSession @p
        if($null -ne $psSession){
            $progresspreference_backup = $progresspreference;
            $progresspreference='SilentlyContinue'
            $p = @{
                Session = $psSession;
                DisableNameChecking = $true;
                AllowClobber= $true;
            }
            [ref]$null = Import-PSSession @p
            #Return original progress preference
            $progresspreference = $progresspreference_backup;
        }
        $O365Object.SafeLinksInfo = Get-SafeLinksInfo
        $O365Object.SafeAttachmentsInfo = Get-SafeAttachmentInfo
        $O365Object.MalwareFilterInfo = Get-MalwareFilterInfo
        $O365Object.AntiPhishingInfo = Get-AntiPhishInfo
        $O365Object.HostedContentFilterInfo = Get-HostedContentFilterInfo
        #Sleep and remove pssession
        Start-Sleep -Milliseconds 10
        Remove-PSSession -Session $psSession
    }
    #>
}
