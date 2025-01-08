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

Function Connect-MonkeyMSGraph {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyMSGraph
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    #Set new params
    $new_params = @{}
    foreach ($param in $O365Object.msal_application_args.GetEnumerator()){
        $new_params.add($param.Key, $param.Value)
    }
    if($O365Object.isConfidentialApp -eq $false){
        Try{
            #Only valid for Interactive authentication
            $useMgGraph = [System.Convert]::ToBoolean($O365Object.internal_config.entraId.mgGraph.useMgGraph)
            $scopes = $O365Object.internal_config.entraId.mgGraph.scopes
        }
        Catch{
            $useMgGraph = $false
            $scopes = $null
        }
        if($useMgGraph -and $scopes){
            #Check if application is present
            if(($O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService MicrosoftGraph)})).Count -gt 0){
                $new_params.publicApp = $O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService MicrosoftGraph)}) | Select-Object -First 1
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
                $clientId = Get-WellKnownAzureService -AzureService MicrosoftGraph
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
                        MessageData = "Unable to get MSAL application for Microsoft Graph";
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'Warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('MicrosoftGraphApplicationError');
                    }
                    Write-Warning @msg
                    return
                }
            }
            #Add scopes
            [void]$new_params.add('Scopes', $scopes)
        }
        Else{
            #Check if application is present
            if(($O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService AzurePowershell)})).Count -gt 0){
                $new_params.publicApp = $O365Object.msal_public_applications.Where({$_.ClientId -eq (Get-WellKnownAzureService -AzureService AzurePowershell)}) | Select-Object -First 1
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
                $clientId = Get-WellKnownAzureService -AzureService AzurePowershell
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
                        MessageData = "Unable to get MSAL application for Microsoft Graph V2";
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'Warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('MicrosoftGraphApplicationError');
                    }
                    Write-Warning @msg
                    return
                }
            }
        }
    }
    #Get endpoint
    $msGraphEndpoint = $O365Object.Environment.Graphv2
    #Add resource to param
    [void]$new_params.add('Resource', $msGraphEndpoint)
    #Try to get token
    Get-MonkeyMSALToken @new_params
}

