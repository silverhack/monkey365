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

function New-MonkeyADALClientCredential {
    <#
     .SYNOPSIS
     Acquires OAuth AccessToken from Azure Active Directory

     .DESCRIPTION
     The New-MonkeyADALClientCredential function lets you acquire an ServicePrincipal OAuth AccessToken from Azure by using
     the Active Directory Authentication Library (ADAL).

     There are five ways to get AccessToken

     1. You can pass a PSCredential object with a ServicePrincipalID and ServicePrincipal password
     2. You can pass a clientId and Certificate file in order to use the certificate credential flow.
     3. You can pass a clientId, Certificate file and Certificate password in order to use the certificate credential flow.
     4. You can pass a clientId and ClientAssertionCertificate in order to use the certificate credential flow.
     5. You can pass a clientId and clientSecret in order to use the client credential flow.

     .PARAMETER InputObject
     PSCredential object

     .PARAMETER clientId
     A registerered ApplicationID as application to the Azure Active Directory.

     .PARAMETER clientSecret
     Secure secret of the client requesting the token.

     .PARAMETER ClientCertificate
     Client certificate of the application requesting the token.

     .PARAMETER CertFilePassword
     Secure password of the certificate

     .PARAMETER ClientAssertionCertificate
     Client assertion certificate of the client requesting the token

     .EXAMPLE
     $Credential = Get-Credential -Message "Please, enter Application Id and secret:"
     $ADALCredential = New-MonkeyADALClientCredential -InputObject $Credential

     This example acquire accesstoken by using Service Principal.

     .EXAMPLE
     $secure = $PlainTextPassword | ConvertTo-SecureString -AsPlainText -Force
     $ADALCredential = New-MonkeyADALClientCredential -ClientCertificate C:\\Mycert.pfx -CertFilePassword $secure -clientId 00000000-0000-0000-0000-000000000000

     This example acquire accesstoken by using Application Certificate credential

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    param
    (
        # pscredential of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObject')]
        [System.Management.Automation.PSCredential] $client_credentials,

        # Identifier of the application requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Parameter(Mandatory = $true, ParameterSetName = "ClientAssertionCertificate")]
        [Parameter(Mandatory = $true, ParameterSetName = "ClientAssertionCertificate-File")]
        [string] $clientId,

        # Identifier of the application requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Security.SecureString] $ClientSecret,

        # Client certificate of the application requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = "ClientAssertionCertificate-File", HelpMessage = 'Please specify the certificate file path')]
        [System.IO.FileInfo]$Certificate,

        # Secure password of the certificate
        [Parameter(Mandatory = $false,HelpMessage = 'Please specify the certificate password')]
        [Security.SecureString] $CertFilePassword,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = "ClientAssertionCertificate")]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate
    )
    ## Check inputObject
    if ($client_credentials -is [pscredential]){
        [string] $clientId = $client_credentials.UserName
        [securestring] $ClientSecret = $client_credentials.Password
    }
    #Check if ClientCredential
    if($ClientSecret){
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $ClientCredential = (New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential -ArgumentList $clientId, ([Microsoft.IdentityModel.Clients.ActiveDirectory.SecureClientSecret]$ClientSecret.Copy()))
    }
    elseif ($Certificate) {
        $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        try{
            if($CertFilePassword){
                $Password = Convert-SecureStringToPlainText -SecureString $CertFilePassword
                $Cert.Import($Certificate,$Password,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
            }
            else{
                $Cert.Import($Certificate,[String]::Empty,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
            }

            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = (New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate -ArgumentList $clientId, $Cert)
        }
        catch{
            Write-Verbose $_
            return $null
        }
    }
    elseif ($ClientAssertionCertificate) {
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = (New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate -ArgumentList $ClientId, $ClientAssertionCertificate)
    }
    if($ClientCredential){
        #Return client credential
        return $ClientCredential
    }
    else{
        return $null
    }
}
