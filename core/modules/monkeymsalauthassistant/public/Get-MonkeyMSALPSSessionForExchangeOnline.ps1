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

Function Get-MonkeyMSALPSSessionForExchangeOnline {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSALPSSessionForExchangeOnline
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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

        [Parameter(Mandatory=$false, HelpMessage="Force refresh token")]
        [Switch]$ForceRefresh,

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
        $AzureEnvironment = Get-MonkeyEnvironment -Environment $Environment
        $isPublicApp = Confirm-IfMSALPublicApp -parameters $PSBoundParameters
        $internal_params = $PSBoundParameters
        if($isPublicApp -eq $false){
            #Remove common params
            $internal_params = Remove-MSALPublicParam -parameters $internal_params
        }
        $EXOSession = $null
        #Set clientId
        if($null -ne $PublicApp -and $PublicApp -is [Microsoft.Identity.Client.PublicClientApplication]){
            if($PublicApp.AppConfig.ClientId -ne (Get-WellKnownAzureService -AzureService ExchangeOnlineV2)){
                #Add clientId and RedirectUri
                $app_param = @{}
                $app_param.ClientId = (Get-WellKnownAzureService -AzureService ExchangeOnlineV2)
                if($PSEdition -eq "Desktop"){
                    $app_param.RedirectUri = (Get-MonkeyExoRedirectUri -Environment $MyParams.Environment)
                }
                if($PSBoundParameters.ContainsKey('TenantId')){
                    $app_param.TenantId = $TenantId
                }
                $exo_app = New-MonkeyMsalApplication @app_param
                [ref]$null = $internal_params.Remove('PublicApp')
                [ref]$null = $internal_params.Add('PublicApp',$exo_app)
            }
        }
        #Add resource
        $internal_params.Add('Resource',$AzureEnvironment.Outlook)
    }
    Process{
        $Ctoken = $null
        $exo_login = Get-MonkeyMSALToken @internal_params
        #Add info to Token
        if($null -ne $exo_login -and $exo_login -is [Microsoft.Identity.Client.AuthenticationResult]){
            #Get TenantId
            if(-NOT $internal_params.ContainsKey("TenantId") -and -NOT $TenantId){
                $TenantId = $exo_login.TenantId
            }
            #Check if interactive or client credentials
            if($isPublicApp -eq $false){
                $tenantName = $null
                #Get Tenant Info
                $internal_params.Resource = $AzureEnvironment.Graph
                $access_token = Get-MonkeyMSALToken @internal_params
                if($null -ne $access_token -and $access_token -is [Microsoft.Identity.Client.AuthenticationResult]){
                    $Tenant = Get-TenantInfo -AuthObject $access_token
                    $tenantName = Get-DefaultTenantName -TenantDetails $Tenant
                }
                if($null -ne $tenantName){
                    #Create PSSession
                    $Authorization = $exo_login.CreateAuthorizationHeader()
                    $Password = ConvertTo-SecureString -AsPlainText $Authorization -Force
                    $UPN = ("MonkeyUser@{0}" -f $tenantName)
                    $Ctoken = New-Object System.Management.Automation.PSCredential -ArgumentList $UPN, $Password
                }
                else{
                    Write-Warning "Missing TenantName"
                    $Ctoken= $null
                }
            }
            else{
                #Get userPrincipalName
                $userPrincipalName = $exo_login.Account.Username
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
                Tags = @('MSALEXOAuth');
                InformationAction = $informationAction;
            }
            Write-Information @msg
            #Add Expiration time
            $EXOSession | Add-Member -type NoteProperty -name ExpiresOn_ -value ([System.DateTimeOffset]::Now.AddMinutes(60)) -Force
            #Add renewable option
            $EXOSession | Add-Member -type NoteProperty -name renewable -value $true -Force
            #Add function to check for near expiration
            $EXOSession | Add-Member -Type ScriptMethod -Name IsNearExpiry -Value {
                return (($this.ExpiresOn_.UtcDateTime.AddMinutes(-5)) -le ((Get-Date).ToUniversalTime()))
            }
            #Add function to disable token renewal
            $EXOSession | Add-Member -Type ScriptMethod -Name DisableRenew -Value {
                $this.renewable = $false
            }
            return $EXOSession
        }
        else{
            #Write message
            Write-Warning $Script:messages.EXOErrorConnection
            return $null
        }
    }
}
