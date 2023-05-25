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

Function Connect-MonkeyComplianceCenter {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyComplianceCenter
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
        if($null -eq $O365Object.exo_msal_application -or ($O365Object.exo_msal_application -isnot [Microsoft.Identity.Client.PublicClientApplication])){
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
            }
            else{
                $msg = @{
                    MessageData = "Unable to get MSAL application for purview";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('PurviewApplicationError');
                }
                Write-Warning @msg
            }
        }
        else{
            $new_params.publicApp = $O365Object.exo_msal_application
        }
    }
    else{
        $O365Object.exo_msal_application = $O365Object.msalapplication
        $new_params.confidentialApp = $O365Object.msalapplication;
    }
    #Connect to Exchange Online Compliance Center
    Get-MonkeyMSALPSSessionForComplianceCenter @new_params
}
