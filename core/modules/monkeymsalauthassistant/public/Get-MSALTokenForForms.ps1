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

Function Get-MSALTokenForForms{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MSALTokenForForms
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        # pscredential of the application requesting the token
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $user_credentials,

        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false)]
        [string] $TenantId,

        [parameter(Mandatory= $false, HelpMessage= "Select an instance of Azure services")]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic",

        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $false)]
        [string] $ClientId,

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-OnBehalfOf')]
        [securestring] $ClientSecret,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate,

        # ClientAssertionCertificate of the application requesting the token
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [System.IO.FileInfo]$certificate,

        # Secure password of the certificate
        [Parameter(Mandatory = $false,ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Please specify the certificate password')]
        [Security.SecureString] $CertFilePassword,

        # Public client application
        [Parameter(Mandatory = $true, ParameterSetName = 'Implicit-PublicApplication')]
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.IPublicClientApplication] $PublicApp,

        # Confidential client application
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialApp,

        # The authorization code received from service authorization endpoint.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [string] $AuthorizationCode,

        # Assertion representing the user.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-OnBehalfOf')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [string] $UserAssertion,

        # Type of the assertion representing the user.
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-OnBehalfOf')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [string] $UserAssertionType,

        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [uri] $RedirectUri,

        # Indicates whether AcquireToken should automatically prompt only if necessary or whether it should prompt regardless of whether there is a cached token.
        [Parameter(Mandatory = $false)]
        [ValidateSet("Always", "Auto", "Never", "RefreshSession","SelectAccount")]
        [String] $PromptBehavior = 'Auto',

        # This parameter will be appended as is to the query string in the HTTP authentication request to the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [string] $extraQueryParameters,

        [Parameter(Mandatory=$false, HelpMessage="Force Authentication Context. Only valid for user&password auth method")]
        [Switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Force silent authentication")]
        [Switch]$Silent,

        [Parameter(Mandatory=$false, HelpMessage="Device code authentication")]
        [Switch]$DeviceCode
    )
    Begin{
        #Get InformationAction
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $informationAction = $PSBoundParameters.informationAction
        }
        else{
            $informationAction = "SilentlyContinue"
        }
        #$isPublicApp = Confirm-IfMSALPublicApp -parameters $PSBoundParameters
        $FormsWellKnownId = Get-WellKnownAzureService -AzureService MicrosoftForms
        <#
        if($isPublicApp -eq $false){
            #Remove common params
            $PSBoundParameters = Remove-MSALPublicParam -parameters $PSBoundParameters
            Write-Warning -Message ($Script:messages.NotAllowedToAuth -f "Microsoft Forms")
        }
        #>
    }
    Process{
        $access_token = Get-MonkeyMSALToken @PSBoundParameters -Resource $FormsWellKnownId;
    }
    End{
        if($null -ne $access_token -and $access_token -is [Microsoft.Identity.Client.AuthenticationResult]){
            #Write message
            $msg = @{
                MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Microsoft Forms")
                Tags = @('MSALSuccessAuth');
                InformationAction = $informationAction;
            }
            Write-Information @msg
            return $access_token
        }
        else{
            #Write message
            Write-Warning -Message ($Script:messages.UnableToGetToken -f "Microsoft Forms")
            return $null
        }
    }
}
