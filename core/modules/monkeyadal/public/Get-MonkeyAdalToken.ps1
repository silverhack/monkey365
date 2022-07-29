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

function Get-MonkeyAdalToken {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAdalToken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'Implicit')]
    param
    (
        # AuthContext
        [Parameter(Mandatory = $false)]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext] $AuthContext,

        # pscredential of the application requesting the token
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $user_credentials,

        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-ConfidentialApp')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [AllowEmptyString()]
        [string] $TenantId,

        [parameter(Mandatory= $false, HelpMessage= "Select an instance of Azure services")]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic",

        # Identifier of the target resource that is the recipient of the requested token.
        [Parameter(Mandatory = $true)]
        [string] $Resource,

        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $false)]
        [string] $ClientId = "1950a258-227b-4e31-a9cf-717495945fc2",

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-OnBehalfOf')]
        [securestring] $ClientSecret,

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject')]
        [System.Management.Automation.PSCredential] $client_credentials,

        # ClientCredential of the application requesting the token
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-OnBehalfOf')]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $client_credentials_app,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate,

        # ClientAssertionCertificate of the application requesting the token
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]$certificate_credentials,

        # ClientAssertionCertificate of the application requesting the token
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [System.IO.FileInfo]$certificate,

        # Secure password of the certificate
        [Parameter(Mandatory = $false,ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Please specify the certificate password')]
        [Security.SecureString] $CertFilePassword,

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
        [uri] $RedirectUri = 'urn:ietf:wg:oauth:2.0:oob',

        # Indicates whether AcquireToken should automatically prompt only if necessary or whether it should prompt regardless of whether there is a cached token.
        [Parameter(Mandatory = $false)]
        [ValidateSet("Always", "Auto", "Never", "RefreshSession","SelectAccount")]
        [String] $PromptBehavior = 'Auto',

        # Identifier of the user the token is requested for.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [string] $UserId,

        # Type of identifier of the user the token is requested for.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType] $UserIdType = 'OptionalDisplayableId',

        # This parameter will be appended as is to the query string in the HTTP authentication request to the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [string] $extraQueryParameters,

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Force Authentication Context. Only valid for user&password auth method")]
        [Switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Force silent authentication")]
        [Switch]$Silent,

        [Parameter(Mandatory=$false,ParameterSetName = 'Implicit', HelpMessage="Device code authentication")]
        [Switch]$DeviceCode
    )
    $token_result = $null
    #Get InformationAction
    if($PSBoundParameters.ContainsKey('InformationAction')){
        $informationAction = $PSBoundParameters.informationAction
    }
    else{
        $informationAction = "SilentlyContinue"
    }
    #Set AuthType
    $AuthType = 'Interactive'
    #Get Environment
    $AzureEnvironment = Get-MonkeyEnvironment -Environment $Environment
    if(-Not $AuthContext){
        if([string]::IsNullOrEmpty($TenantId) -or $TenantId -eq [System.Guid]::Empty){
            [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext] $AuthenticationContext = Get-MonkeyADALAuthenticationContext -Login $AzureEnvironment.Login
        }
        else{
            [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext] $AuthenticationContext = Get-MonkeyADALAuthenticationContext -Login $AzureEnvironment.Login -TenantID $TenantID
        }
    }
    else{
        $AuthenticationContext = $AuthContext
    }
    switch -Wildcard ($PSCmdlet.ParameterSetName) {
        "ClientSecret-InputObject" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $ClientCredential = New-MonkeyADALClientCredential -clientId $client_credentials.UserName -ClientSecret $client_credentials.Password
            break
        }
        "ClientSecret-ConfidentialApp" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $ClientCredential = $client_credentials_app
            break
        }
        "ClientSecret-App" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $ClientCredential = New-MonkeyADALClientCredential -clientId $ClientId -ClientSecret $ClientSecret
            break
        }
        "ClientAssertionCertificate-InputObject" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = $certificate_credentials
            break
        }
        "ClientAssertionCertificate-File" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = New-MonkeyADALClientCredential -clientId $ClientId -Certificate $certificate -CertFilePassword $CertFilePassword
            break
        }
        "ClientAssertionCertificate*" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = New-MonkeyADALClientCredential -ClientId $ClientId -ClientAssertionCertificate $ClientAssertionCertificate
            break
        }
    }
    switch -Wildcard ($PSCmdlet.ParameterSetName) {
        'Implicit' {
            #Get platform params
            $fnc_args = @{
                PromptBehavior = $PromptBehavior;
                ForceAuth = $ForceAuth.IsPresent;
            }
            $PlatformParameters = New-MonkeyADALPlatformParam @fnc_args
            $UserIdentifier = New-MonkeyAdalUserIdentifier $UserId -Type $UserIdType
            if ($extraQueryParameters) {
                $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $PlatformParameters, $UserIdentifier, $extraQueryParameters)
            }
            elseif ($UserId) {
                $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $PlatformParameters, $UserIdentifier)
            }
            if($DeviceCode){
                $AuthType = 'Device_Code'
                #Get Auth token from Azure
                $code = $AuthenticationContext.AcquireDeviceCodeAsync($Resource, $ClientId).Result
                Write-Information -MessageData $code.Message -InformationAction Continue
                $token_result = $AuthenticationContext.AcquireTokenByDeviceCodeAsync($code)
            }
            elseif($null -ne $user_credentials){
                [string] $account_name = $user_credentials.UserName
                if($account_name.Contains("@")){
                    $aad_creds = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential" -ArgumentList $user_credentials.UserName.ToString(),$user_credentials.password
                    $token_result = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($AuthenticationContext,$Resource,$ClientId,$aad_creds)
                }
            }
            elseif($Silent){
                $token_result = $AuthenticationContext.AcquireTokenSilentAsync($Resource, $ClientId)
            }
            else {
                $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $PlatformParameters)
            }
            break
        }
        "ClientSecret-App" {
            $AuthType = 'Client_Credentials'
            $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientCredential)
            break
        }
        "ClientSecret-InputObject" {
            $AuthType = 'Client_Credentials'
            $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientCredential)
            break
        }
        "ClientAssertionCertificate-InputObject" {
            $AuthType = 'Certificate_Credentials'
            $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientCredential)
            break
        }
        "ClientAssertionCertificate-File" {
            $AuthType = 'Certificate_Credentials'
            $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientCredential)
            break
        }
        "ClientAssertionCertificate" {
            $AuthType = 'Certificate_Credentials'
            $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientCredential)
            break
        }
        "*AuthorizationCode" {
            $AuthType = 'Authorization_Code'
            $token_result = $AuthenticationContext.AcquireTokenByAuthorizationCodeAsync($AuthorizationCode, $RedirectUri, $ClientCredential, $Resource)
            break
        }
        "*OnBehalfOf" {
            $AuthType = 'OnBehalfOf'
            [Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion] $UserAssertionObj = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion -ArgumentList $UserAssertion, $UserAssertionType
            $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientCredential, $UserAssertionObj)
            break
        }
    }
    #Complete task
    if($null -ne $token_result){
        #Wait until task is completed
        while ($token_result.IsCompleted -ne $true) { Start-Sleep -Seconds 5;}
    }
    #Check if failed task
    if($token_result.IsFaulted){
        if("ErrorCode" -in $token_result.Exception.InnerException.psobject.properties.Name){
            #switch errors
            switch ($token_result.Exception.InnerException.ErrorCode){
                failed_to_acquire_token_silently{
                    #Write message
                    Write-Debug -Message $script:messages.AcquireSilentTokenFailed
                    Write-Warning -Message $token_result.Exception.InnerException.Message
                    Write-Verbose -Message $token_result.Exception
                    #Write message
                    Write-Debug -Message $token_result.Exception.InnerException.StackTrace
                    #Remove Silent
                    [ref]$null = $PSBoundParameters.Remove('Silent')
                    #$AuthenticationContext = $null
                    #Get-MonkeyAdalToken @PSBoundParameters
                    $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $PlatformParameters)
                    while ($token_result.IsCompleted -ne $true) { Start-Sleep -Milliseconds 500;}
                }
                multiple_matching_tokens_detected{
                    #Clear adal cache token
                    Clear-MonkeyADALTokenCache
                    #Sleeping
                    Start-Sleep -Seconds 2
                    #Get-MonkeyAdalToken @PSBoundParameters
                    $token_result = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $PlatformParameters)
                    while ($token_result.IsCompleted -ne $true) { Start-Sleep -Milliseconds 500;}
                }
                Default{
                    Write-Warning -Message $token_result.Exception.InnerException.Message
                    #Write message
                    Write-Verbose -Message ($script:messages.AdalUnknownError -f $token_result.Exception.InnerException.ErrorCode)
                    #Write message
                    Write-Debug -Message $token_result.Exception.InnerException.StackTrace
                }
            }
        }
        else{
            Write-Warning -Message $token_result.Exception.InnerException.Message
            #Write debug
            Write-Debug -Message $token_result.Exception.InnerException.StackTrace
        }
    }
    if($null -ne $token_result.Result){
        $p = @{
            MessageData = ("Successfully authenticated to {0}" -f $Resource);
            InformationAction = $informationAction;
        }
        Write-Information @p
        #add elements to auth object
        $new_token = $token_result.Result
        $new_token | Add-Member -type NoteProperty -name AuthType -value $AuthType -Force
        $new_token | Add-Member -type NoteProperty -name resource -value $Resource -Force
        $new_token | Add-Member -type NoteProperty -name clientId -value $ClientId -Force
        #Add TenantId
        if('TenantId' -in $new_token.psobject.properties.Name -and $null -eq $new_token.TenantId){
            $new_token | Add-Member -type NoteProperty -name TenantId -value $TenantId -Force
        }
        #return new token
        return $new_token
    }
    else{
        #Write message
        Write-Debug -Message ($script:messages.AccessTokenErrorMessage -f $Resource)
        if($token_result.IsFaulted){
            Write-Warning -Message $token_result.Exception.InnerException.Message
            Write-Verbose -Message $token_result.Exception
            #Write message
            Write-Debug -Message $token_result.Exception.InnerException.StackTrace
        }
        return $null
    }
}
