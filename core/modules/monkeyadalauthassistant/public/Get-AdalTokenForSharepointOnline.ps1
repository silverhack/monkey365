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

Function Get-AdalTokenForSharepointOnline {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AdalTokenForSharepointOnline
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        # AuthContext
        [Parameter(Mandatory = $false)]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext] $AuthContext,

        # pscredential of the application requesting the token
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [System.Management.Automation.PSCredential] $user_credentials,

        [parameter(Mandatory= $false, ParameterSetName = 'Implicit', HelpMessage= "User for access to the O365 services")]
        [String]$UserPrincipalName,

        [parameter(Mandatory= $false, HelpMessage= "Sharepoint Url")]
        [String]$Endpoint,

        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-ConfidentialApp')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [string] $TenantId,

        [parameter(Mandatory= $false, HelpMessage= "Select an instance of Azure services")]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic",

        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [string] $ClientId,

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [securestring] $ClientSecret,

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject')]
        [System.Management.Automation.PSCredential] $client_credentials,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate,

        # ClientAssertionCertificate of the application requesting the token
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [parameter(Mandatory= $false, HelpMessage= "pfx certificate file")]
        [ValidateScript(
            {
            if( -Not ($_ | Test-Path) ){
                throw ("The cert file does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The argument must be a PFX file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.pfx)"){
                throw "The certificate specified argument must be of type pfx"
            }
            return $true
        })]
        [System.IO.FileInfo]$certificate,

        # Secure password of the certificate
        [Parameter(Mandatory = $false,ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Please specify the certificate password')]
        [Security.SecureString] $CertFilePassword,

        # ClientCredential of the application requesting the token
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $client_credentials_app,

        # ClientAssertionCertificate of the application requesting the token
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-ConfidentialApp')]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]$certificate_credentials,

        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false)]
        [uri] $RedirectUri,

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

        # Indicates whether AcquireToken should automatically prompt only if necessary or whether it should prompt regardless of whether there is a cached token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [ValidateSet("Always", "Auto", "Never", "RefreshSession","SelectAccount")]
        [String] $PromptBehavior = 'Auto',

        # This parameter will be appended as is to the query string in the HTTP authentication request to the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [string] $extraQueryParameters,

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Force Authentication Context. Only valid for user&password auth method")]
        [Switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Force silent authentication")]
        [Switch]$Silent,

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Device code authentication")]
        [Switch]$DeviceCode,

        [Parameter(Mandatory=$false, HelpMessage="Connect Sharepoint Admin Url")]
        [Switch]$Admin,

        [Parameter(Mandatory=$false, HelpMessage="Connect Sharepoint Siteroot Url")]
        [Switch]$rootSite,

        [Parameter(Mandatory=$false, HelpMessage="Connect Sharepoint Siteroot Url")]
        [Switch]$oneDrive
    )
    Begin{
        #Get InformationAction
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $informationAction = $PSBoundParameters.informationAction
        }
        else{
            $informationAction = "SilentlyContinue"
        }
        $sps_login = $null
        $Tenant = $null
        $sharepointUrl = $null
        $AzureEnvironment = Get-MonkeyEnvironment -Environment $Environment
        $isPublicApp = Confirm-IfPublicApp -parameters $PSBoundParameters
        $internal_params = $PSBoundParameters
        if($isPublicApp -eq $false){
            #Remove common params
            $internal_params = Remove-PublicParams -parameters $internal_params
        }
        $auth_params = Get-AdalAuthParameters -parameters $internal_params
        $access_token = Get-MonkeyAdalToken @auth_params -Resource $AzureEnvironment.Graph;
        if($null -ne $access_token -and $access_token -is [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult]){
            $Tenant = Get-TenantInfo -AuthObject $access_token
        }
        if($Endpoint){
            $sharepointUrl = $Endpoint
        }
        elseif($Admin){
            if($null -ne $Tenant){
                $sharepointUrl = Get-SharepointAdminUrl -TenantDetails $Tenant
            }
        }
        elseif($rootSite){
            if($null -ne $Tenant){
                $sharepointUrl = Get-SharepointUrl -TenantDetails $Tenant
            }
        }
        elseif($oneDrive){
            if($null -ne $Tenant){
                $sharepointUrl = Get-OneDriveUrl -TenantDetails $Tenant
            }
        }
        else{
            if($null -ne $Tenant){
                #Connect to Sharepoint Admin Url
                $sharepointUrl = Get-SharepointAdminUrl -TenantDetails $Tenant
            }
        }
        #Set clientId
        if($isPublicApp){
            $auth_params.Add('ClientId',(Get-WellKnownAzureService -AzureService SharePointOnline))
            $auth_params.Add('RedirectUri',"https://oauth.spops.microsoft.com/")
        }
        #Add resource
        $auth_params.Add('Resource',$sharepointUrl)
    }
    Process{
        if(![string]::IsNullOrEmpty($sharepointUrl)){
            $sps_login = Get-MonkeyAdalToken @auth_params
        }
    }
    End{
        if($null -ne $sps_login -and $sps_login -is [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult]){
            #Write message
            $msg = @{
                MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Sharepoint Online")
                Tags = @('adalSuccessAuth');
                InformationAction = $informationAction;
            }
            Write-Information @msg
            return $sps_login
        }
        else{
            #Write message
            Write-Warning -Message ($Script:messages.UnableToGetToken -f "Sharepoint Online")
            return $null
        }
    }
}
