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

Function Connect-MonkeyExchangeOnline {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyExchangeOnline
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="parameters")]
        [Object]$parameters
    )
    #Set new params
    $new_params = @{}
    foreach ($param in $parameters.GetEnumerator()){
        $new_params.add($param.Key, $param.Value)
    }
    #Check if confidential App
    if($O365Object.isConfidentialApp -eq $false){
        #Check if application is present
        if(($O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService ExchangeOnlineV2)})).Count -gt 0){
            $new_params.publicApp = $O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService ExchangeOnlineV2)}) | Select-Object -First 1
        }
        Else{
            #Potentially first time the user is authenticating, so we use original parameters
            $new_params = @{}
            foreach ($param in $O365Object.msal_application_args.GetEnumerator()){
                $new_params.add($param.Key, $param.Value)
            }
            #Create a new msal client application
            $client_app = @{}
            foreach ($param in $O365Object.application_args.GetEnumerator()){
                $client_app.add($param.Key, $param.Value)
            }
            $p = @{
                app_params = $client_app;
                Environment = $O365Object.initParams.Environment;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $exo_app = New-MsalApplicationForExo @p
            if($null -ne $exo_app){
                $O365Object.exo_msal_application = $exo_app
                $new_params.publicApp = $O365Object.exo_msal_application
                #Add to Object
                [void]$O365Object.msal_public_applications.Add($exo_app)
            }
            else{
                $msg = @{
                    MessageData = "Unable to get MSAL application for Exchange Online";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('ExchangeOnlineApplicationError');
                }
                Write-Warning @msg
            }
        }
    }
    else{
        $O365Object.exo_msal_application = $O365Object.msalapplication
        $new_params.confidentialApp = $O365Object.msalapplication;
    }
    #Connect to Exchange Online
    Get-MonkeyMSALPSSessionForExchangeOnline @new_params
}
