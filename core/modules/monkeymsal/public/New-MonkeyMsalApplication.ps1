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

function New-MonkeyMsalApplication{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyMsalApplication
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false, HelpMessage = 'Application Id')]
        [string] $clientId = "1950a258-227b-4e31-a9cf-717495945fc2",

        # Client secret
        [Parameter(Mandatory = $false, HelpMessage = 'Client Secret')]
        [Security.SecureString] $clientsecret = [Security.SecureString]::new(),

        # pscredential of the application requesting the token
        [Parameter(Mandatory = $false, HelpMessage = 'PsCredential')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential] $client_credentials,

        # Client certificate
        [Parameter(Mandatory = $false, HelpMessage = 'Please specify the certificate file path')]
        [System.IO.FileInfo] $certificate,

        [Parameter(Mandatory = $false, HelpMessage = 'Please specify the certificate password')]
        [Security.SecureString] $certfilepassword,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $false)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate,

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
        [string] $Instance
    )
    Begin{
        $Verbose = $Debug = $False;
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
        #Set clientId
        if($PSBoundParameters.ContainsKey('clientId') -and $PSBoundParameters.clientId){
            $clientId = $PSBoundParameters.clientId
        }
        else{
            $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
        }
        $az_application = $null
        $certificateApp = $false
        $isPublicApp = $true
        if($certificate){
            $certificateApp = $true
            $isPublicApp = $false
        }
        ## Check inputObject
        if ($client_credentials) {
            [string] $clientId = $client_credentials.UserName
            [securestring] $clientsecret = $client_credentials.Password
        }
        if($clientsecret.Length -gt 0 -or $certificate){
            $isPublicApp = $false
        }
        #Set parameters
        if($clientsecret.Length -gt 0 -and -NOT $isPublicApp){
            $az_args = @{
                applicationId = $clientId;
                ClientSecret = $clientsecret;
                RedirectUri = $RedirectUri
                TenantId =$TenantId;
                Environment = $Environment;
                Instance = $Instance;
                isPublicApp = $isPublicApp;
            }
        }
        else{
            $az_args = @{
                applicationId = $clientId;
                RedirectUri = $RedirectUri
                TenantId =$TenantId;
                Environment = $Environment;
                Instance = $Instance;
                isPublicApp = $isPublicApp;
            }
        }
        if(!$certificateApp){
            #Get options
            $options = New-MonkeyMsalApplicationClientOptions @az_args
            if($options -is [Microsoft.Identity.Client.ConfidentialClientApplicationOptions]){
                $application_builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::CreateWithApplicationOptions($options)
            }
            elseif ($options -is [Microsoft.Identity.Client.PublicClientApplicationOptions]){
                $application_builder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($options)
            }
            if($RedirectUri){
                $p = @{
                    Message = ($script:messages.UsingRedirectUri -f $RedirectUri.AbsoluteUri);
                    Verbose = $verbose;
                }
                Write-Verbose @p
                [void] $application_builder.WithRedirectUri($RedirectUri.AbsoluteUri)
            }
            if(-NOT $RedirectUri -or $null -eq $options.RedirectUri -and $options -is [Microsoft.Identity.Client.PublicClientApplicationOptions]) {
                $p = @{
                    Message = ($script:messages.UsingDefaultRedirectUri);
                    Verbose = $verbose;
                }
                Write-Verbose @p
                [void] $application_builder.WithDefaultRedirectUri()
            }
        }
        else{
            $az_args = @{
                applicationId = $clientId;
                RedirectUri = $RedirectUri
                TenantId =$TenantId;
                Environment = $Environment;
                Instance = $Instance;
                isPublicApp = $isPublicApp;
            }
            $options = New-MonkeyMsalApplicationClientOptions @az_args
            $application_builder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::CreateWithApplicationOptions($options)
            if($TenantId){
                $p = @{
                    Message = ($script:messages.UsingTenantId -f $TenantId);
                    Verbose = $verbose;
                }
                Write-Verbose @p
                [void]$application_builder.WithTenantId($TenantId)
            }
            if($RedirectUri){
                $p = @{
                    Message = ($script:messages.UsingDefaultRedirectUri);
                    Verbose = $verbose;
                }
                Write-Verbose @p
                [void] $application_builder.WithDefaultRedirectUri()
            }
        }
    }
    Process{
        if($application_builder){
            try{
                #Check if certificate credentials
                if($certificate -and $application_builder -is [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]){
                    #$Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $client_cert = [System.IO.File]::ReadAllBytes($certificate)
                    if($certfilepassword){
                        $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($client_cert, $certfilepassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
                    }
                    else{
                        $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($client_cert, [String]::Empty, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
                    }
                    #Add cert options
                    [void]$application_builder.WithCertificate($Cert);
                }
                elseif($ClientAssertionCertificate -and $application_builder -is [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]){
                    #Add cert options
                    [void]$application_builder.WithCertificate($ClientAssertionCertificate);
                }
            }
            catch{
                Write-Verbose $_.Exception.Message
                return
            }
            #Build application
            try{
                $az_application = $application_builder.Build()
            }
            catch{
                Write-Verbose $_.Exception.Message
                Write-Debug $_
            }
        }
    }
    End{
        if($null -ne $az_application){
            #Add isPublicApp to object
            $az_application | Add-Member -type NoteProperty -name isPublicApp -value $isPublicApp -Force
            return $az_application
        }
    }
}
