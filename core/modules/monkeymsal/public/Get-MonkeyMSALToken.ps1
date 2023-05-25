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

Function Get-MonkeyMSALToken{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSALToken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'Implicit')]
    [OutputType([Microsoft.Identity.Client.AuthenticationResult])]
    Param (
        # pscredential of the application requesting the token
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [System.Management.Automation.PSCredential] $user_credentials,

        [parameter(Mandatory= $false, ParameterSetName = 'Implicit', HelpMessage= "User for access to the O365 services")]
        [String]$UserPrincipalName,

        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [AllowEmptyString()]
        [string] $TenantId,

        [parameter(Mandatory= $false, HelpMessage= "Select an instance of Azure services")]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic",

        [parameter(Mandatory= $true, HelpMessage= "Resource to connect")]
        [String]$Resource,

        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'Implicit')]
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

        # Public client application
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Microsoft.Identity.Client.IPublicClientApplication] $PublicApp,

        # Confidential client application
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialApp,

        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false)]
        [uri] $RedirectUri,

        # The authorization code received from service authorization endpoint.
        [string] $AuthorizationCode,

        # Assertion representing the user.
        [Parameter(Mandatory = $false)]
        [string] $UserAssertion,

        # Type of the assertion representing the user.
        [Parameter(Mandatory = $false)]
        [string] $UserAssertionType,

        # Indicates whether AcquireToken should automatically prompt only if necessary or whether it should prompt regardless of whether there is a cached token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [ValidateSet("Always", "Auto", "Never", "RefreshSession","SelectAccount")]
        [String] $PromptBehavior = 'Auto',

        # This parameter will be appended as is to the query string in the HTTP authentication request to the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [string] $extraQueryParameters,

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Force Authentication Context. Only valid for user&password auth method")]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Force silent authentication")]
        [Switch]$Silent,

        [Parameter(Mandatory=$false, HelpMessage="Force refresh token")]
        [Switch]$ForceRefresh,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Device code authentication")]
        [Switch]$DeviceCode,

        [Parameter(Mandatory=$false, HelpMessage="scopes")]
        [array]$Scopes
    )
    $Verbose = $False;
    $Debug = $False;
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
    #Set AuthType and authContext
    $AuthType = 'Interactive'
    $authContext = $null
    #Setting scopes
    if ($PSBoundParameters.ContainsKey('Scopes')){
        if($Resource -match '/$'){
            foreach($scp in $Scopes){
                [string[]]$scope += ("{0}{1}" -f $Resource,$scp)
            }
        }
        else{
            foreach($scp in $Scopes){
                [string[]]$scope += ("{0}/{1}" -f $Resource,$scp)
            }
        }
    }
    else{
        if($Resource -match '/$'){
            [string[]]$scope = ("{0}.default" -f $Resource)
        }
        else{
            [string[]]$scope = ("{0}/.default" -f $Resource)
            #[string[]]$scope = ("{0}/user_impersonation" -f $Resource)
        }
    }
    $extra_params=@(
        'Resource',
        'AuthMode',
        'PromptBehavior',
        'Silent',
        'DeviceCode'
    )
    $app_params = @{}
    foreach ($param in $PSBoundParameters.GetEnumerator()){
        if ($param.key -in $extra_params) { continue }
        $app_params.add($param.Key, $param.Value)
    }
    #Get Azure instance
    #[Microsoft.Identity.Client.AzureCloudInstance]$AzureInstance = [Microsoft.Identity.Client.AzureCloudInstance]::$Environment
    switch -Wildcard ($PSCmdlet.ParameterSetName) {
        'Implicit' {
            [Microsoft.Identity.Client.PublicClientApplication]$app = New-MonkeyMsalApplication @app_params
        }
        'Implicit-PublicApplication' {
            [Microsoft.Identity.Client.PublicClientApplication]$app = $PublicApp
        }
        "ClientSecret-App" {
            [Microsoft.Identity.Client.IConfidentialClientApplication]$app = New-MonkeyMsalApplication @app_params
        }
        "ClientSecret-InputObject" {
            $app_params.applicationId = $client_credentials.UserName
            $app_params.clientSecret = $client_credentials.Password
            [Microsoft.Identity.Client.IConfidentialClientApplication]$app = New-MonkeyMsalApplication @app_params
        }
        'ClientSecret-ConfidentialApp' {
            [Microsoft.Identity.Client.IConfidentialClientApplication]$app = $ConfidentialApp
        }
        "ClientAssertionCertificate-File" {
            [Microsoft.Identity.Client.IConfidentialClientApplication]$app = New-MonkeyMsalApplication @app_params
        }
        "ClientAssertionCertificate" {
            [Microsoft.Identity.Client.IConfidentialClientApplication]$app = New-MonkeyMsalApplication @app_params
        }
        "ClientSecret-OnBehalfOf" {
            [Microsoft.Identity.Client.IConfidentialClientApplication]$app = New-MonkeyMsalApplication @app_params
        }
    }
    #Check if app is created
    if($null -eq $app){
        $p = @{
            MessageData = ($script:messages.UnableToCreateApplication);
            Verbose = $verbose;
        }
        Write-Verbose @p
        return $null
    }
    #Get auth token
    if($app.isPublicApp){
        if($PromptBehavior -eq "Auto"){
            $Prompt = "SelectAccount"
        }
        elseif($ForceAuth -or $PromptBehavior -eq "Always"){
            $Prompt = "ForceLogin"
        }
        elseif($PromptBehavior -eq "RefreshSession"){
            $Prompt = $null;
        }
        else{
            $Prompt = $PromptBehavior
        }
        if ($user_credentials) {
            $authContext = $app.AcquireTokenByUsernamePassword($scope, $user_credentials.UserName, $user_credentials.Password)
        }
        elseif($DeviceCode.IsPresent){
            $AuthType = 'Device_Code'
            $authContext = $app.AcquireTokenWithDeviceCode($scope, [DeviceCodeHelper]::GetDeviceCodeResultCallback())
        }
        elseif ($PSBoundParameters.ContainsKey("Silent") -and $Silent.IsPresent) {
            if ($userPrincipalName) {
                $p = @{
                    MessageData = ($script:messages.UsingLoginHint -f $userPrincipalName);
                    Verbose = $verbose;
                }
                Write-Verbose @p
                $authContext = $app.AcquireTokenSilent($scope, $userPrincipalName)
            }
            else {
                [Microsoft.Identity.Client.IAccount] $Account = $app.GetAccountsAsync().GetAwaiter().GetResult() | Select-Object -First 1
                if($Account){
                    $authContext = $app.AcquireTokenSilent($scope, $Account)
                }
                else{
                    Write-Verbose ($script:messages.AccountWasNotFound);
                    [ref]$null = $PSBoundParameters.Remove('Silent')
                    Get-MonkeyMSALToken @PSBoundParameters
                }
            }
            If($PromptBehavior -eq "RefreshSession" -or ($PSBoundParameters.ContainsKey('ForceRefresh') -and $ForceRefresh.IsPresent)){
                $p = @{
                    Message = ($script:messages.RefreshingToken);
                    Verbose = $verbose;
                }
                Write-Verbose @p
                #Force refresh
                [void]$authContext.WithForceRefresh($ForceRefresh)
            }
        }
        else{
            $authContext = $app.AcquireTokenInteractive($scope)
            [IntPtr] $ParentWindow = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
            if ($ParentWindow) { [void] $authContext.WithParentActivityOrWindow($ParentWindow) }
            if ($Prompt){
                [void] $authContext.WithPrompt([Microsoft.Identity.Client.Prompt]::$Prompt)
            }
            If($PSBoundParameters.ContainsKey('UseEmbeddedWebView')){
                [void]$authContext.WithUseEmbeddedWebView($UseEmbeddedWebView)
            }
        }
    }
    else{
        #Get authentication type
        if($null -ne $app.AppConfig.ClientCredentialCertificate){
            $AuthType = 'Certificate_Credentials'
        }
        else{
            $AuthType = 'Client_Credentials'
        }
        if($AuthorizationCode){
            $authContext = $app.AcquireTokenForClient($scope, $AuthorizationCode)
        }
        else{
            $authContext = $app.AcquireTokenForClient($scope)
            if ($PSBoundParameters.ContainsKey('ForceRefresh') -and $ForceRefresh.IsPresent){
                [void]$authContext.WithForceRefresh($ForceRefresh)
            }
        }
    }
    if($null -ne $authContext){
        $token_result = $authContext.ExecuteAsync();
        while ($token_result.IsCompleted -ne $true){
            Start-Sleep -Milliseconds 500;
        }
        if($token_result.IsFaulted){
            Write-Warning ($script:messages.AcquireTokenFailed -f $token_result.Exception.InnerException.message)
            Write-Verbose ($script:messages.AcquireTokenFailed -f $token_result.Exception.InnerException.ErrorCode)
            #Detailed error
            Write-Debug $token_result.Exception.InnerException
        }
        if($null -ne $token_result.Result){
            #add elements to auth object
            $new_token = $token_result.Result
            $new_token | Add-Member -type NoteProperty -name AuthType -value $AuthType -Force
            $new_token | Add-Member -type NoteProperty -name resource -value $Resource -Force
            $new_token | Add-Member -type NoteProperty -name clientId -value $app.ClientId -Force
            $new_token | Add-Member -type NoteProperty -name renewable -value $true -Force
            #Add TenantId
            if('TenantId' -in $new_token.psobject.properties.Name -and $null -eq $new_token.TenantId){
                if($TenantId){
                    $tid = $TenantId
                }
                elseif($app.AppConfig.TenantId){
                    $tid = $app.AppConfig.TenantId
                }
                else{
                    $tid = $null
                }
                $new_token | Add-Member -type NoteProperty -name TenantId -value $tid -Force
            }
            #Add function to check for near expiration
            $new_token | Add-Member -Type ScriptMethod -Name IsNearExpiry -Value {
                return ($this.ExpiresOn.UtcDateTime.AddMinutes(-15) -lt [System.Datetime]::UtcNow)
            }
            #Add function to disable token renewal
            $new_token | Add-Member -Type ScriptMethod -Name DisableRenew -Value {
                $this.renewable = $false
            }
            #return new token
            return $new_token
        }
        else{
            #Write message
            Write-Debug -Message ($script:messages.AccessTokenErrorMessage -f $Resource)
            return $null
        }
    }
}
