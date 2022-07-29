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

function New-MonkeyMSALApplicationClientOptions{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyMSALApplicationClientOptions
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    param
    (
        # application id
        [Parameter(Mandatory = $false, HelpMessage = 'Application Id')]
        [string] $applicationId = "1950a258-227b-4e31-a9cf-717495945fc2",
        # Client secret
        [Parameter(Mandatory = $false, HelpMessage = 'Client Secret')]
        [Security.SecureString] $ClientSecret,
        # return address
        [parameter(Mandatory=$false)]
        [uri] $RedirectUri,
        # Tenant identifier of the authority to issue token.
        [parameter(Mandatory=$false)]
        [string] $TenantId,
        # Azure AD Instance
        [parameter(Mandatory=$false)]
        [Microsoft.Identity.Client.AzureCloudInstance]$Environment = [Microsoft.Identity.Client.AzureCloudInstance]::AzurePublic,
        [parameter(Mandatory=$false)]
        [string] $Instance,
        [Parameter(Mandatory=$false, HelpMessage="is PUblic application")]
        [Switch]$isPublicApp
    )
    Begin{
        if($isPublicApp){
            $client_options = [Microsoft.Identity.Client.PublicClientApplicationOptions]::new()
        }
        else{
            $client_options = [Microsoft.Identity.Client.ConfidentialClientApplicationOptions]::new()
        }
    }
    Process{
        #Add redirect uri
        if($RedirectUri){
            $client_options.RedirectUri = $RedirectUri
        }
        #Add tenant Id
        if($TenantId){
            $client_options.TenantId = $TenantId
        }
        #Add client secret
        if($ClientSecret){
            $client_options.ClientSecret = (Convert-SecureStringToPlainText -SecureString $ClientSecret)
        }
        #Set Azure Instance
        if($Instance){
            $client_options.Instance = $Instance
        }
        elseif($Environment -and -NOT $Instance){
            $client_options.AzureCloudInstance = $Environment
        }
        #Set application Id
        $client_options.ClientId = $applicationId

        #add options
        if(-NOT $TenantId){
            $aadAuthority = [Microsoft.Identity.Client.AadAuthorityAudience]::AzureAdAndPersonalMicrosoftAccount
            $client_options.AadAuthorityAudience = $aadAuthority
        }
    }
    End{
        return $client_options
    }
}
