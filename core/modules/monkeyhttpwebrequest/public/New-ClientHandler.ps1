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

Function New-ClientHandler{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-ClientHandler
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Net.Http.HttpClientHandler])]
    Param (
        [parameter(Mandatory=$False, HelpMessage='Automatic decompresion')]
        [switch]$AutomaticDecompression,

        [parameter(Mandatory=$False, HelpMessage='Cookie container')]
        [System.Net.CookieContainer]$CookieContainer,

        [Parameter(HelpMessage="Maximum redirection")]
        [ValidateRange(1,65535)]
        [int32]$MaxRedirections = 40,

        [parameter(Mandatory=$False, HelpMessage='control redirects')]
        [Bool]$AllowAutoRedirect = $true,

        [parameter(Mandatory=$False, HelpMessage='Disable SSL Verification')]
        [switch]$DisableSSLVerification
    )
    Begin{
        #Create Handler
        $handler = [System.Net.Http.HttpClientHandler]::new()
    }
    Process{
        #Check if disable ssl certs
        if($PSBoundParameters.ContainsKey('DisableSSLVerification') -and $PSBoundParameters['DisableSSLVerification'].IsPresent){
            # Attach a custom validation callback that saves the remote certificate to the hashtable
            $handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator
            <#
            $handler.ServerCertificateCustomValidationCallback = {
                param(
                    [System.Net.Http.HttpRequestMessage]$Msg,
                    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert,
                    [System.Security.Cryptography.X509Certificates.X509Chain]$Chain,
                    [System.Net.Security.SslPolicyErrors]$SslErrors
                )
                $uri = $($requestMessage.RequestUri)
                # return true all certs
                return [System.Net.Security.SslPolicyErrors]::None -eq $SslErrors
            }.GetNewClosure()
            #>
        }
        #Check if cookie container
        if($PSBoundParameters.ContainsKey('CookieContainer')){
            $handler.CookieContainer = $CookieContainer
        }
        #Check max automatic redirections
        if($PSBoundParameters.ContainsKey('MaxRedirections') -and $PSBoundParameters['MaxRedirections']){
            $handler.MaxAutomaticRedirections = $PSBoundParameters['MaxRedirections'];
        }
        #Check automatic decompression
        if($PSBoundParameters.ContainsKey('AutomaticDecompression') -and $PSBoundParameters['AutomaticDecompression']){
            $handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
        }
        #Check automatic redirects
        if($PSBoundParameters.ContainsKey('AllowAutoRedirect')){
            $handler.AllowAutoRedirect = $PSBoundParameters['AllowAutoRedirect'];
        }
    }
    End{
        return $handler
    }
}