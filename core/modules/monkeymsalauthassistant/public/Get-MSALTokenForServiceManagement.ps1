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

Function Get-MSALTokenForServiceManagement{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MSALTokenForServiceManagement
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "", Scope="Function")]
    [CmdletBinding()]
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
        [Security.SecureString]$CertficatePassword,

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

        [parameter(Mandatory= $false, HelpMessage= "Resource to connect")]
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
    Process{
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
        $access_token = Get-MonkeyMSALToken @internal_params -Resource $AzureEnvironment.Servicemanagement;
        if($null -ne $access_token -and $access_token -is [Microsoft.Identity.Client.AuthenticationResult]){
            #Write message
            $msg = @{
                MessageData = ($Script:messages.TokenAcquiredInfoMessage -f "Service Management")
                Tags = @('MSALSuccessAuth');
                InformationAction = $informationAction;
            }
            Write-Information @msg
            return $access_token
        }
        else{
            #Write message
            Write-Warning -Message ($Script:messages.UnableToGetToken -f "Service Management")
            return $null
        }
    }
}
