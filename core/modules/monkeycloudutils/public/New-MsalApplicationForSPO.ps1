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

Function New-MsalApplicationForSPO{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MsalApplicationForSPO
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False, ParameterSetName='application params')]
        [System.Collections.Hashtable]$app_params,

        [parameter(Mandatory = $False)]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic",

        [parameter(Mandatory = $False)]
        [Switch]$ForceDesktop
    )
    Begin{
        #Set vars
        $redirectUri = $null
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        #Get ClientId
        $clientId = Get-WellKnownAzureService -AzureService SharePointOnline
        #Get redirectUri
        If($PSEdition -eq "Desktop" -or ($PSBoundParameters.ContainsKey('ForceDesktop') -and $PSBoundParameters['ForceDesktop'])){
            $redirectUri = "https://oauth.spops.microsoft.com/"
        }
    }
    Process{
        #Create a new app
        if(-NOT $PSBoundParameters.ContainsKey('app_params')){
            #Create new application hashtable
            $app_params = @{
                clientId = $clientId;
                RedirectUri = $redirectUri;
                Verbose = $Verbose;
                Debug = $Debug;
                InformationAction = $InformationAction;
                Environment = $Environment;
            }
        }
        Else{
            if(-NOT $app_params.ContainsKey('clientId')){
                #Add clientId
                [ref]$null = $app_params.Add('clientId',$clientId)
            }
            else{
                $app_params.ClientId = $clientId
            }
            if($null -ne $redirectUri){
                if(-NOT $app_params.ContainsKey('redirectUri')){
                    #Add redirect uri
                    [ref]$null = $app_params.Add('redirectUri',$redirectUri)
                }
                else{
                    $app_params.redirectUri = $redirectUri
                }
            }
        }
    }
    End{
        try{
            New-MonkeyMsalApplication @app_params
        }
        catch{
            $msg = @{
                Message = ($Script:messages.MSALApplicationError -f "SharePoint Online");
                InformationAction = $InformationAction;
                Verbose = $Verbose;
                Debug = $Debug;
            }
            Write-Verbose @msg
        }
    }
}