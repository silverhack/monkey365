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

    Param (
        [Parameter(Mandatory=$false, HelpMessage="parameters")]
        [Object]$parameters
    )
    if($O365Object.isUsingAdalLib){
        Get-MonkeyAdalPSSessionForComplianceCenter @parameters
    }
    else{
        #Set new params
        $new_params = @{}
        foreach ($param in $parameters.GetEnumerator()){
            $new_params.add($param.Key, $param.Value)
        }
        #Check if confidential App
        if($O365Object.isConfidentialApp -eq $false){
            if($null -eq $O365Object.exo_msal_application){
                #Create a new msal client application
                $client_app = $O365Object.application_args.Clone()
                #Add clientId and RedirectUri
                $client_app.ClientId = (Get-WellKnownAzureService -AzureService ExchangeOnlineV2)
                if($PSEdition -eq "Desktop"){
                    $client_app.RedirectUri = (Get-MonkeyExoRedirectUri -Environment $O365Object.initParams.Environment)
                }
                try{
                    $exo_app = New-MonkeyMsalApplication @client_app
                    if($null -ne $exo_app){
                        $O365Object.exo_msal_application = $exo_app
                        $new_params.publicApp = $O365Object.exo_msal_application
                    }
                }
                catch{
                    $msg = @{
                        MessageData = "Unable to connect to Exchange Online Compliance Center";
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'error';
                        InformationAction = $script:InformationAction;
                        Tags = @('ExchangeOnlineConnectionError');
                    }
                    Write-Error @msg
                    $msg.MessageData = $_
                    Write-Error @msg
                    $exo_app = $null
                    return
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
        Write-Host ($new_params | Out-String)
        Write-Host ($new_params.publicApp | Out-String)
        Get-MonkeyMSALPSSessionForComplianceCenter @new_params
    }
}
