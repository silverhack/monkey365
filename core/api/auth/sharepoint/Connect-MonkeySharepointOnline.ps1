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

Function Connect-MonkeySharepointOnline {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeySharepointOnline
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$false, HelpMessage="parameters")]
        [Object]$parameters
    )
    if($O365Object.isUsingAdalLib){
        Get-AdalTokenForSharepointOnline @parameters
    }
    else{
        <#
        There is a problem with MSAL, the SharePoint Online application and the localhost replyUrl. Using the classic powershell app instead
        #Set new params
        $new_params = @{}
        foreach ($param in $parameters.GetEnumerator()){
            $new_params.add($param.Key, $param.Value)
        }
        #Check if confidential App
        if($O365Object.isConfidentialApp -eq $false){
            if($null -eq $O365Object.sps_msal_application){
                #Public App
                $app2 = $O365Object.msal_application_args.Clone()
                #Add clientId and RedirectUri
                $app2.ClientId = (Get-WellKnownAzureService -AzureService SharePointOnline)
                if($PSEdition -eq "Desktop"){
                    $app2.RedirectUri = "https://oauth.spops.microsoft.com/"
                }
                $sps_app = New-MonkeyMsalApplication @app2
                if($null -ne $sps_app){
                    $O365Object.sps_msal_application = $sps_app
                }
                $new_params.publicApp = $O365Object.sps_msal_application
            }
            else{
                $new_params.publicApp = $O365Object.sps_msal_application
            }
        }
        else{
            $O365Object.sps_msal_application = $O365Object.msalapplication
            $new_params.confidentialApp = $O365Object.msalapplication;
        }
        #>
        #Connect to Sharepoint Online
        Get-MSALTokenForSharepointOnline @parameters
    }
}
