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

Function Get-MonkeyAdalPSSessionForExchangeOnline {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAdalPSSessionForExchangeOnline
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
        $AzureEnvironment = Get-MonkeyEnvironment -Environment $Environment
        $isPublicApp = Confirm-IfPublicApp -parameters $PSBoundParameters
        $internal_params = $PSBoundParameters
        if($isPublicApp -eq $false){
            #Remove common params
            $internal_params = Remove-PublicParams -parameters $internal_params
        }
        $EXOSession = $null
        #Set clientId
        if($isPublicApp){
            $internal_params.Add('ClientId',(Get-WellKnownAzureService -AzureService ExchangeOnlineV2))
            $internal_params.Add('RedirectUri',(Get-MonkeyExoRedirectUri -Environment $Environment))
        }
        #Add resource
        $internal_params.Add('Resource',$AzureEnvironment.Outlook)
    }
    Process{
        $Ctoken = $null
        $exo_login = Get-MonkeyAdalToken @internal_params
        #Add info to Token
        if($null -ne $exo_login -and $exo_login -is [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult]){
            #Get TenantId
            if(-NOT $PSBoundParameters.ContainsKey("TenantId") -and -NOT $TenantId){
                $TenantId = $exo_login.TenantId
            }
            #Check if interactive or client credentials
            if($isPublicApp -eq $false -and $TenantId){
                $tenantName = $null
                #Get Tenant Info
                $PSBoundParameters.Resource = $AzureEnvironment.Graph
                $access_token = Get-MonkeyAdalToken @PSBoundParameters
                if($null -ne $access_token -and $access_token -is [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult]){
                    $Tenant = Get-TenantInfo -AuthObject $access_token
                    $tenantName = Get-DefaultTenantName -TenantDetails $Tenant
                }
                #Create PSSession
                if($null -ne $tenantName){
                    $Authorization = $exo_login.CreateAuthorizationHeader()
                    $Password = ConvertTo-SecureString -AsPlainText $Authorization -Force
                    $UPN = ("MonkeyUser@{0}" -f $tenantName)
                    $Ctoken = New-Object System.Management.Automation.PSCredential -ArgumentList $UPN, $Password
                }
                else{
                    $Ctoken = $null
                }
            }
            else{
                #Get userPrincipalName
                $userPrincipalName = $exo_login.UserInfo.DisplayableId
                if($userPrincipalName){
                    #Create PSSession
                    $Authorization = $exo_login.CreateAuthorizationHeader()
                    $Password = ConvertTo-SecureString -AsPlainText $Authorization -Force
                    $Ctoken = New-Object System.Management.Automation.PSCredential -ArgumentList $userPrincipalName, $Password
                }
                else{
                    Write-Verbose -Message $Script:messages.UnableToGetUPN
                }
            }
            #Try to create a valid PSSession
            if($null -ne $Ctoken){
                $params = @{
                    ConfigurationName = 'Microsoft.Exchange'
                    ConnectionUri = ("{0}?BasicAuthToOAuthConversion=true" -f $AzureEnvironment.ExchangeOnline)
                    Credential = $Ctoken
                    Authentication = "Basic"
                    AllowRedirection = $true
                    ErrorAction = "Stop"
                }
                try{
                    $EXOSession = New-PSSession @params
                }
                catch{
                    Write-Verbose -Message $_
                }
            }
        }
    }
    End{
        if($null -ne $EXOSession -and $EXOSession -is [System.Management.Automation.Runspaces.PSSession]){
            #Write message
            $msg = @{
                MessageData = $Script:messages.EXOSuccessfullyConnected;
                Tags = @('adalEXOAuth');
                InformationAction = $informationAction;
            }
            Write-Information @msg
            return $EXOSession
        }
        else{
            #Write message
            Write-Warning $Script:messages.EXOErrorConnection
            return $null
        }
    }
}
