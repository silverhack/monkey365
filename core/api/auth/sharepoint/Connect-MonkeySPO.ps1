﻿# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
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
        [Parameter(Mandatory=$true, HelpMessage="Connect SharePoint Url")]
        [string]$Endpoint,

        [Parameter(Mandatory=$false, ParameterSetName = 'Admin', HelpMessage="Connect SharePoint Admin Url")]
        [Switch]$Admin,

        [Parameter(Mandatory=$false, ParameterSetName = 'rootSite', HelpMessage="Connect SharePoint Siteroot Url")]
        [Switch]$RootSite,

        [Parameter(Mandatory=$false, ParameterSetName = 'oneDrive', HelpMessage="Connect OneDrive Url")]
        [Switch]$OneDrive
    )
    try{
        $sharepointUrl = $spo_app = $null;
        #Get Environment
        $CloudType = $O365Object.initParams.Environment
        $sps_p = @{
            Endpoint = $PSBoundParameters['Endpoint'];
            Environment = $CloudType;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        #Get Endpoint
        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            'Admin' {
                $sharepointUrl = Get-SharepointAdminUrl @sps_p
            }
            'rootSite' {
                $sharepointUrl = Get-SharepointUrl @sps_p
            }
            'oneDrive' {
                $sharepointUrl = Get-OneDriveUrl @sps_p
            }
            Default {
                $sharepointUrl = Get-SharepointUrl @sps_p
            }
        }
        try{
            $usePnpManagementShell = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.UsePnPManagementShell)
        }
        catch{
            $usePnpManagementShell = $false
        }
        if($null -ne $sharepointUrl){
            #Set new params
            $new_params = @{}
            foreach ($param in $O365Object.msal_application_args.GetEnumerator()){
                $new_params.add($param.Key, $param.Value)
            }
            #Check if confidential App
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
                    #Set new params
                    $new_params = @{}
                    foreach ($param in $O365Object.msalAuthArgs.GetEnumerator()){
                        $new_params.add($param.Key, $param.Value)
                    }
                    #Create a new MSAL application
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
                        #Check if force MSAL desktop
                        if($null -ne $O365Object.SystemInfo -and $O365Object.SystemInfo.MsalType -eq 'Desktop'){
                            $p.Item('ForceDesktop') = $true
                        }
                        #Get Application for SPO
                        $spo_app = New-MsalApplicationForSPO @p
                    }
                    if($null -ne $spo_app){
                        #Validate .net core conflicts
                        try{
                            if($spo_app.AppConfig.RedirectUri -match "localhost" -and $O365Object.SystemInfo.MsalType -eq "Core"){
                                $dc = $new_params.Item('DeviceCode');
                                if($null -eq $dc -or $dc -eq $false){
                                    $msg = @{
                                        MessageData = "Unable to connect SharePoint Online. SharePoint Online Management Shell is not supporting interactive authentication on .NET core. Use DeviceCode instead. For more info, please check the following url: https://silverhack.github.io/monkey365/authentication/limitations/";
                                        callStack = (Get-PSCallStack | Select-Object -First 1);
                                        logLevel = 'Warning';
                                        InformationAction = $O365Object.InformationAction;
                                        Tags = @('MonkeySPOAuthenticationError');
                                    }
                                    Write-Warning @msg
                                    return
                                }
                            }
                            $new_params.publicApp = $spo_app
                            #Add to Object
                            [void]$O365Object.msal_public_applications.Add($spo_app)
                        }
                        Catch{
                            Write-Error $_
                            return
                        }
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
                $new_params.confidentialApp = $O365Object.msalapplication;
            }
            #Add SharePoint url to object
            [void]$new_params.Add('Resource',$sharepointUrl);
            #Add scopes if PnP application is used
            if($usePnpManagementShell){
                [string[]]$scope = "AllSites.Read"
                [void]$new_params.Add('Scopes',$scope);
            }
            #Connect to SharePoint Online
            Get-MSALTokenForSharePointOnline @new_params
        }
    }
    catch{
        Write-Error $_
    }
}
