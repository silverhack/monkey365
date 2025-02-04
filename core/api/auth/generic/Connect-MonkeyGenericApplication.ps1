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

Function Connect-MonkeyGenericApplication {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyGenericApplication
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="Azure service")]
        [String]$AzureService = "AzurePowershell",

        [Parameter(Mandatory=$true, HelpMessage="Resource to connect")]
        [String]$Resource,

        [Parameter(Mandatory=$false, HelpMessage="Redirect URI")]
        [String]$RedirectUri
    )
    Begin{
        #Set new params
        $new_params = @{}
        foreach ($param in $O365Object.msal_application_args.GetEnumerator()){
            $new_params.add($param.Key, $param.Value)
        }
    }
    Process{
        if($O365Object.isConfidentialApp -eq $false){
            #Check if application is present
            if(($O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService ("{0}" -f $AzureService))})).Count -gt 0){
                $new_params.publicApp = $O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService ("{0}" -f $AzureService))}) | Select-Object -First 1
                #Add silent
                if(-NOT $new_params.ContainsKey('Silent')){
                    #Add silent auth
                    [ref]$null = $new_params.Add('Silent',$true)
                }
            }
            Else{
                #Potentially first time the user is authenticating, so we use original parameters
                #Set new params
                $new_params = @{}
                foreach ($param in $O365Object.msalAuthArgs.GetEnumerator()){
                    $new_params.add($param.Key, $param.Value)
                }
                #Set new params for application
                $client_app = @{}
                foreach ($param in $O365Object.application_args.GetEnumerator()){
                    $client_app.add($param.Key, $param.Value)
                }
                #Get ClientId from Microsoft Graph
                $clientId = Get-WellKnownAzureService -AzureService $AzureService
                if($clientId){
                    #Add to param
                    [void]$client_app.add('ClientId', $clientId)
                    #Get application
                    $publicApp = New-MonkeyMsalApplication @client_app
                    if($publicApp){
                        #Add public app to param
                        $new_params.publicApp = $publicApp
                        #Add to Object
                        [void]$O365Object.msal_public_applications.Add($publicApp)
                    }
                    Else{
                        $msg = @{
                            MessageData = ("Unable to get MSAL application for {0}" -f $clientId);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'Warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('MonkeyGenericApplicationError');
                        }
                        Write-Warning @msg
                        return
                    }
                }
                Else{
                    $msg = @{
                        MessageData = "ClientId was not found";
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'Warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('MonkeyGenericApplicationClientIdError');
                    }
                    Write-Warning @msg
                    return
                }
            }
            #Add redirect URI if present
            if($PSBoundParameters.ContainsKey('RedirectUri') -and $PSBoundParameters['RedirectUri']){
                $new_params.publicApp.RedirectUri = $PSBoundParameters['RedirectUri'];
            }
        }
        #Add resource to param
        [void]$new_params.add('Resource', $Resource)
        #Try to get token
        $access_token = Get-MonkeyMSALToken @new_params
        If($null -ne $access_token -and $access_token -is [Microsoft.Identity.Client.AuthenticationResult]){
            #Write message
            $msg = @{
                MessageData = $Script:message.TokenAcquiredGenericMessage
                Tags = @('MSALSuccessAuth');
                InformationAction = $O365Object.InformationAction;
            }
            Write-Information @msg
            return $access_token
        }
    }
    End{
        #Clean redirect uri
        If(($PSBoundParameters.ContainsKey('RedirectUri') -and $PSBoundParameters['RedirectUri'])){
            if($O365Object.isConfidentialApp -eq $false){
                #Get app
                $app = $O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService ("{0}" -f $AzureService))}) | Select-Object -First 1
                if($app){
                    #Remove Redirect Uri
                    $app.RedirectUri = $null;
                }
            }
        }
    }
}

