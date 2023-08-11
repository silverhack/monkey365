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

Function Connect-MonkeySPO {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeySPO
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="parameters")]
        [Object]$parameters,

        [Parameter(Mandatory=$false, ParameterSetName = 'Endpoint', HelpMessage="Connect SharePoint Url")]
        [string]$Endpoint,

        [Parameter(Mandatory=$false, ParameterSetName = 'Admin', HelpMessage="Connect SharePoint Admin Url")]
        [Switch]$Admin,

        [Parameter(Mandatory=$false, ParameterSetName = 'rootSite', HelpMessage="Connect SharePoint Siteroot Url")]
        [Switch]$rootSite,

        [Parameter(Mandatory=$false, ParameterSetName = 'oneDrive', HelpMessage="Connect OneDrive Url")]
        [Switch]$oneDrive
    )
    $sharepointUrl = $companyInfo = $null;
    #Set new params
    $new_params = @{}
    foreach ($param in $parameters.GetEnumerator()){
        $new_params.add($param.Key, $param.Value)
    }
    if($null -ne $O365Object.Tenant -and $null -ne $O365Object.Tenant.Psobject.Properties.Item('CompanyInfo')){
        $companyInfo = $O365Object.Tenant.CompanyInfo
    }
    else{
        Write-Warning "Not connected to MSGraph"
    }
    #Get Endpoint
    switch -Wildcard ($PSCmdlet.ParameterSetName) {
        'Endpoint' {
            $sharepointUrl = $Endpoint
        }
        'Admin' {
            if($null -ne $companyInfo){
                $sharepointUrl = Get-SharepointAdminUrl -TenantDetails $companyInfo
            }
            else{
                Write-Warning "Unable to get SharePoint Online admin url"
            }
        }
        'rootSite' {
            if($null -ne $companyInfo){
                $sharepointUrl = Get-SharepointUrl -TenantDetails $companyInfo
            }
            else{
                Write-Warning "Unable to get SharePoint Online root url"
            }
        }
        'oneDrive' {
            if($null -ne $companyInfo){
                $sharepointUrl = Get-OneDriveUrl -TenantDetails $companyInfo
            }
            else{
                Write-Warning "Unable to get OneDrive url"
            }
        }
        Default {
            if($null -ne $companyInfo){
                $sharepointUrl = Get-SharepointUrl -TenantDetails $companyInfo
            }
            else{
                Write-Warning "Unable to get SharePoint Online url"
            }
        }
    }
    try{
        $usePnpManagementShell = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.UsePnPManagementShell)
    }
    catch{
        $usePnpManagementShell = $false
    }
    if($null -ne $sharepointUrl){
        #Get SharePoint Online application
        if($O365Object.isConfidentialApp -eq $false){
            #Check if application is present
            if(($O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService SharePointOnline)})).Count -gt 0){
                $new_params.publicApp = $O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService SharePointOnline)}) | Select-Object -First 1
            }
            ElseIf(($O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService SharePointPnP)})).Count -gt 0){
                $new_params.publicApp = $O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService SharePointPnP)}) | Select-Object -First 1
            }
            Else{
                #Potentially first time the user is authenticating, so we use original parameters
                $new_params = @{}
                foreach ($param in $O365Object.msal_application_args.GetEnumerator()){
                    $new_params.add($param.Key, $param.Value)
                }
                #Create new SPO application
                $client_app = @{}
                foreach ($param in $O365Object.application_args.GetEnumerator()){
                    $client_app.add($param.Key, $param.Value)
                }
                $p = @{
                    Environment = $O365Object.initParams.Environment;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                if($usePnpManagementShell){
                    $spo_app = New-MsalApplicationForPnP @p
                }
                else{
                    if($O365Object.SystemInfo.OSVersion -ne 'windows' -and -NOT $new_params.ContainsKey('DeviceCode')){
                        $msg = @{
                            MessageData = "Unable to connect SharePoint Online. SharePoint Online Management Shell is not supporting interactive authentication on .NET core. Use DeviceCode instead";
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'Warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('SPOAuthenticationError');
                        }
                        Write-Warning @msg
                        return
                    }
                    #Get Application for SPO
                    $spo_app = New-MsalApplicationForSPO @p
                }
                if($null -ne $spo_app){
                    $O365Object.sps_msal_application = $spo_app
                    $new_params.publicApp = $spo_app
                    #Add to Object
                    [void]$O365Object.msal_public_applications.Add($spo_app)
                }
                else{
                    $msg = @{
                        MessageData = "Unable to get MSAL application for SharePoint Online";
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'Warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('SPOPublicApplicationError');
                    }
                    Write-Warning @msg
                    return
                }
            }
        }
        else{
            $O365Object.sps_msal_application = $O365Object.msalapplication
            $new_params.confidentialApp = $O365Object.msalapplication;
        }
        #Add SharePoint url to object
        [void]$new_params.Add('Endpoint',$sharepointUrl);
        #Add scopes if PnP application is used
        if($usePnpManagementShell){
            [string[]]$scope = "AllSites.Read"
            [void]$new_params.Add('Scopes',$scope);
        }
        #Connect to SharePoint Online
        Get-MSALTokenForSharePointOnline @new_params
    }
}
