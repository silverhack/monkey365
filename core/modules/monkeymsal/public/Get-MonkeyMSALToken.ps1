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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("InjectionRisk.StaticPropertyInjection", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'Implicit')]
    [OutputType([Microsoft.Identity.Client.AuthenticationResult])]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit', HelpMessage = 'Application Id')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App', HelpMessage = 'Application Id')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate', HelpMessage = 'Application Id')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Application Id')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-IntegratedWindowsAuth', HelpMessage = 'Application Id')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-InputObject', HelpMessage = 'Application Id')]
        [String]$ClientId = "1950a258-227b-4e31-a9cf-717495945fc2",

        [parameter(Mandatory= $false, ParameterSetName = 'Implicit', HelpMessage= "User for access to the O365 services")]
        [String]$UserPrincipalName,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [System.Management.Automation.PSCredential]$UserCredentials,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App', HelpMessage = 'Client Secret')]
        [Security.SecureString]$ClientSecret = [Security.SecureString]::new(),

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject', HelpMessage = 'PsCredential')]
        [Alias('client_credentials')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]$ClientCredentials,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Certificate file path')]
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
        [System.IO.FileInfo]$Certificate,

        [Parameter(Mandatory = $false,ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Certificate password')]
        [Security.SecureString]$CertFilePassword,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate', HelpMessage = 'Client assertion certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientAssertionCertificate,

        [parameter(Mandatory=$false, HelpMessage = 'Redirect URI')]
        [System.Uri]$RedirectUri,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [String]$TenantId,

        [parameter(Mandatory=$false, HelpMessage = 'Environment')]
        [Microsoft.Identity.Client.AzureCloudInstance]$Environment = [Microsoft.Identity.Client.AzureCloudInstance]::AzurePublic,

        [parameter(Mandatory=$false, HelpMessage = 'Instance')]
        [String]$Instance,

        [parameter(Mandatory=$false, HelpMessage = 'Authority')]
        [System.Uri]$Authority,

        [Parameter(Mandatory = $true, ParameterSetName = 'Implicit-PublicApplication')]
        [Microsoft.Identity.Client.IPublicClientApplication] $PublicApp,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialApp,

        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode')]
        [String] $AuthorizationCode,

        [parameter(Mandatory= $true, HelpMessage= "Resource to connect")]
        [String]$Resource,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [ValidateSet("SelectAccount", "NoPrompt", "Never", "ForceLogin")]
        [String] $PromptBehavior = 'SelectAccount',

        # Ignore any access token in the user token cache and attempt to acquire new access token using the refresh token for the account if one is available.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-ConfidentialApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientAssertionCertificate-File')]
        [Switch]$ForceRefresh,

        [Parameter(Mandatory=$false, HelpMessage="scopes")]
        [Array]$Scopes,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-InputObject')]
        [String[]] $ExtraScopesToConsent,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-IntegratedWindowsAuth')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Switch] $IntegratedWindowsAuth,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-IntegratedWindowsAuth')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-InputObject')]
        [String] $LoginHint,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication', HelpMessage="Device code authentication")]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-InputObject', HelpMessage="Device code authentication")]
        [Switch]$DeviceCode,

        [Parameter(Mandatory=$false, HelpMessage="Force silent authentication")]
        [Switch]$Silent,

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Force Authentication Context. Only valid for user&password auth method")]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Switch]$ForceAuth
    )
    Begin{
        #Set authType
        $AuthType = 'Interactive'
        $application = $authContext = $null;
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction') -and $PSBoundParameters['InformationAction']){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
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
            }
        }
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'ClientSecret-ConfidentialApp'){
            $application = $PSBoundParameters['ConfidentialApp']
        }
        Elseif($PSCmdlet.ParameterSetName -eq 'Implicit-PublicApplication'){
            $application = $PSBoundParameters['PublicApp']
        }
        else{
            #Get command metadata
            $AppOptions = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-MonkeyMSALApplication")
            #Set new dict
            $newPsboundParams = [ordered]@{}
            $param = $AppOptions.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
            #Add verbose, debug, etc..
            [void]$newPsboundParams.Add('InformationAction',$InformationAction)
            [void]$newPsboundParams.Add('Verbose',$Verbose)
            [void]$newPsboundParams.Add('Debug',$Debug)
            #Get application
            $application = New-MonkeyMsalApplication @newPsboundParams
        }
    }
    End{
        if($null -ne $application){
            try{
                if($application -is [Microsoft.Identity.Client.PublicClientApplication]){
                    If($PSBoundParameters.ContainsKey("ForceAuth") -and $PSBoundParameters['ForceAuth'].IsPresent){
                        $PromptBehavior = "ForceLogin"
                    }
                    If ($PSBoundParameters.ContainsKey("UserCredentials") -and $PSBoundParameters['UserCredentials']) {
                        $authContext = $application.AcquireTokenByUsernamePassword($scope, $UserCredentials.UserName, $UserCredentials.Password)
                    }
                    ElseIf ($PSBoundParameters.ContainsKey("DeviceCode") -and $PSBoundParameters['DeviceCode']) {
                        $AuthType = 'Device_Code'
                        $authContext = $application.AcquireTokenWithDeviceCode($scope, [DeviceCodeHelper]::GetDeviceCodeResultCallback())
                    }
                    ElseIf ($PSBoundParameters.ContainsKey("Silent") -and $PSBoundParameters['Silent'].IsPresent) {
                        If ($PSBoundParameters.ContainsKey("UserPrincipalName") -and $PSBoundParameters['UserPrincipalName']){
                            $p = @{
                                MessageData = ($script:messages.UsingLoginHint -f $UserPrincipalName);
                                Verbose = $verbose;
                            }
                            Write-Verbose @p
                            $authContext = $application.AcquireTokenSilent($scope, $UserPrincipalName)
                        }
                        Else {
                            [Microsoft.Identity.Client.IAccount] $Account = $application.GetAccountsAsync().GetAwaiter().GetResult() | Select-Object -First 1
                            if($Account){
                                $authContext = $application.AcquireTokenSilent($scope, $Account)
                            }
                            Else{
                                Write-Verbose ($script:messages.AccountWasNotFound);
                                [ref]$null = $PSBoundParameters.Remove('Silent')
                                Get-MonkeyMSALToken @PSBoundParameters
                            }
                        }
                        If($null -ne $authContext -and $PSBoundParameters.ContainsKey('ForceRefresh') -and $PSBoundParameters['ForceRefresh'].IsPresent){
                            $p = @{
                                Message = ($script:messages.RefreshingToken);
                                Verbose = $verbose;
                            }
                            Write-Verbose @p
                            #Force refresh
                            [void]$authContext.WithForceRefresh($ForceRefresh)
                        }
                    }
                    Else{
                        $authContext = $application.AcquireTokenInteractive($scope)
                        [IntPtr] $ParentWindow = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
                        if ($ParentWindow) { [void] $authContext.WithParentActivityOrWindow($ParentWindow) }
                        if ($PromptBehavior){
                            [void] $authContext.WithPrompt([Microsoft.Identity.Client.Prompt]::$PromptBehavior)
                        }
                        Else{
                            [void] $authContext.WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount)
                        }
                        If($PSBoundParameters.ContainsKey('UseEmbeddedWebView')){
                            [void]$authContext.WithUseEmbeddedWebView($UseEmbeddedWebView)
                        }
                    }
                }
                else{
                    #Get authentication type
                    if($null -ne $application.AppConfig.ClientCredentialCertificate){
                        $AuthType = 'Certificate_Credentials'
                    }
                    else{
                        $AuthType = 'Client_Credentials'
                    }
                    if($PSBoundParameters.ContainsKey('AuthorizationCode') -and $PSBoundParameters['AuthorizationCode']){
                        $authContext = $application.AcquireTokenByAuthorizationCode($scope, $PSBoundParameters['AuthorizationCode'])
                    }
                    else{
                        $authContext = $application.AcquireTokenForClient($scope)
                        if ($PSBoundParameters.ContainsKey('ForceRefresh') -and $PSBoundParameters['ForceRefresh'].IsPresent){
                            [void]$authContext.WithForceRefresh($ForceRefresh)
                        }
                    }
                }
                if($PSBoundParameters.ContainsKey('TenantId') -and $PSBoundParameters['TenantId']){
                    [void]$authContext.WithAuthority($PSBoundParameters['Environment'],$PSBoundParameters['TenantId'])
                }
                if($PSBoundParameters.ContainsKey('Authority') -and $PSBoundParameters['Authority']){
                    [void]$authContext.WithAuthority($PSBoundParameters['Authority'].AbsoluteUri)
                }
                if($null -ne $authContext){
                    #Create cancellationtoken
                    $cancelationToken = [System.Threading.CancellationTokenSource]::new()
                    try{
                        $token_result = $authContext.ExecuteAsync($cancelationToken.Token);
                        while ($token_result.IsCompleted -ne $true){
                            Start-Sleep -Milliseconds 500;
                        }
                    }
                    Finally{
                        if (!$token_result.IsCompleted) {
                            $cancelationToken.Cancel()
                        }
                        $cancelationToken.Dispose()
                    }
                    if($token_result.IsFaulted){
                        Write-Warning ($script:messages.AcquireTokenFailed -f $token_result.Exception.InnerException.message)
                        $ErrorCode = $token_result.Exception.InnerException | Select-Object -ExpandProperty ErrorCode -ErrorAction Ignore
                        Write-Verbose ($script:messages.AcquireTokenFailed -f $ErrorCode)
                        #Detailed error
                        Write-Debug $token_result.Exception.InnerException
                        #Retrying authentication without silent parameter
                        if($application -is [Microsoft.Identity.Client.PublicClientApplication] -and $PSBoundParameters.ContainsKey('Silent')){
                            Write-Warning $script:messages.RemoveSilentParameter;
                            [ref]$null = $PSBoundParameters.Remove('Silent')
                            Get-MonkeyMSALToken @PSBoundParameters
                            return
                        }
                    }
                    if($null -ne $token_result.Result){
                        #add elements to auth object
                        $new_token = $token_result.Result
                        $new_token | Add-Member -type NoteProperty -name AuthType -value $AuthType -Force
                        $new_token | Add-Member -type NoteProperty -name resource -value $Resource -Force
                        $new_token | Add-Member -type NoteProperty -name clientId -value $application.ClientId -Force
                        $new_token | Add-Member -type NoteProperty -name renewable -value $true -Force
                        #Add TenantId
                        if($null -ne $new_token.psobject.properties.Item('TenantId') -and $null -eq $new_token.TenantId){
                            if($TenantId){
                                $tid = $TenantId
                            }
                            elseif($application.AppConfig.TenantId){
                                $tid = $application.AppConfig.TenantId
                            }
                            else{
                                $tid = $null
                            }
                            $new_token | Add-Member -type NoteProperty -name TenantId -value $tid -Force
                        }
                        #Add function to check for near expiration
                        $new_token | Add-Member -Type ScriptMethod -Name IsNearExpiry -Value {
                            return ([System.Datetime]::UtcNow -gt $this.ExpiresOn.UtcDateTime.AddMinutes(-15))
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
            Catch{
                Write-Error $_
            }
        }
    }
}


