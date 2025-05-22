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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "", Scope="Function")]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit', HelpMessage = 'Application Id')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App', HelpMessage = 'Application Id')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate', HelpMessage = 'Application Id')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Application Id')]
        [String]$ClientId = "1950a258-227b-4e31-a9cf-717495945fc2",

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App', HelpMessage = 'Client Secret')]
        [Security.SecureString]$ClientSecret = [Security.SecureString]::new(),

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject', HelpMessage = 'PsCredential')]
        [Alias('client_credentials')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]$ClientCredentials,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Certificate file path')]
        [System.IO.FileInfo]$Certificate,

        [Parameter(Mandatory = $false,ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Certificate password')]
        [Security.SecureString]$CertFilePassword,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate', HelpMessage = 'Client assertion certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientAssertionCertificate,

        [parameter(Mandatory=$false, HelpMessage = 'Redirect URI')]
        [System.Uri]$RedirectUri,

        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [String]$TenantId,

        [parameter(Mandatory=$false, HelpMessage = 'Environment')]
        [Microsoft.Identity.Client.AzureCloudInstance]$Environment = [Microsoft.Identity.Client.AzureCloudInstance]::AzurePublic,

        [parameter(Mandatory=$false, HelpMessage = 'Instance')]
        [String]$Instance,

        [parameter(Mandatory=$false, HelpMessage = 'Authority')]
        [System.Uri]$Authority,

        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.PublicClientApplicationOptions]$PublicClientOptions,

        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.ConfidentialClientApplicationOptions] $ConfidentialClientOptions
    )
    Begin{
        $appBuilder = $newApplication = $null;
        $Verbose = $Debug = $isPublicApp = $False;
        #Check if public or confidential application
        if($PSCmdlet.ParameterSetName -eq 'Implicit' -or $PSCmdlet.ParameterSetName -eq 'PublicClient-InputObject'){
            $isPublicApp = $true
        }
        else{
            $isPublicApp = $false
        }
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $DebugPreference = 'Continue'
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction') -and $PSBoundParameters['InformationAction']){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            "PublicClient*" {
                $appBuilder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($PublicClientOptions)
            }
            "ConfidentialClient*" {
                $appBuilder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::CreateWithApplicationOptions($ConfidentialClientOptions)
            }
            "*" {
                #Get command metadata
                $AppOptions = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-MonkeyMSALApplicationClientOptions")
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
                #Add isPublicApp to parameters
                [void]$newPsboundParams.Add('IsPublicApp',$isPublicApp)
                ## Check inputObject
                if ($PSBoundParameters.ContainsKey('ClientCredentials') -and $PSBoundParameters['ClientCredentials']) {
                    [void]$newPsboundParams.Add('ClientId',$ClientCredentials.UserName)
                    [void]$newPsboundParams.Add('ClientSecret',$ClientCredentials.Password)
                }
                #Get client options
                $ClientOptions = New-MonkeyMsalApplicationClientOptions @newPsboundParams
                #Create application
                if($isPublicApp){
                    $appBuilder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($ClientOptions)
                }
                else{
                    $appBuilder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::CreateWithApplicationOptions($ClientOptions)
                }
            }
        }
    }
    Process{
        try{
            if($null -ne $appBuilder){
                #Add redirect Uri
                if ($PSBoundParameters.ContainsKey('RedirectUri') -and $PSBoundParameters['RedirectUri']) {
                    $p = @{
                        Message = ($script:messages.UsingRedirectUri -f $RedirectUri.AbsoluteUri);
                        Verbose = $verbose;
                    }
                    Write-Verbose @p
                    [void]$appBuilder.WithRedirectUri($RedirectUri.AbsoluteUri)
                }
                else{
                    if($isPublicApp){
                        $p = @{
                            Message = ($script:messages.UsingDefaultRedirectUri);
                            Verbose = $verbose;
                        }
                        Write-Verbose @p
                        [void] $appBuilder.WithDefaultRedirectUri()
                    }
                }
                #Add TenantId
                if ($PSBoundParameters.ContainsKey('TenantId') -and $PSBoundParameters['TenantId']) {
                    $p = @{
                        Message = ($script:messages.UsingTenantId -f $TenantId);
                        Verbose = $verbose;
                    }
                    Write-Verbose @p
                    [void]$appBuilder.WithTenantId($TenantId)
                }
                #Add Certificate options
                if ($PSBoundParameters.ContainsKey('Certificate') -and $PSBoundParameters['Certificate']) {
                    $client_cert = [System.IO.File]::ReadAllBytes($PSBoundParameters['Certificate'])
                    if ($PSBoundParameters.ContainsKey('CertFilePassword') -and $PSBoundParameters['CertFilePassword']) {
                        $Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($client_cert, $PSBoundParameters['CertFilePassword'], [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
                    }
                    else{
                        $Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($client_cert, [String]::Empty, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
                    }
                    #Add cert options
                    [void]$appBuilder.WithCertificate($Cert);
                }
                Elseif ($PSBoundParameters.ContainsKey('ClientAssertionCertificate') -and $PSBoundParameters['ClientAssertionCertificate']) {
                    #Add cert options
                    [void]$appBuilder.WithCertificate($PSBoundParameters['ClientAssertionCertificate']);
                }
            }
            #Add Authority
            if($PSBoundParameters.ContainsKey('Authority') -and $PSBoundParameters['Authority']) {
                #Add Authority
                [void]$appBuilder.WithAuthority($PSBoundParameters['Authority'].AbsoluteUri)
            }
            #Build application
            $newApplication = $appBuilder.Build()
            #Add isPublicApp to object
            $newApplication | Add-Member -type NoteProperty -name isPublicApp -value $isPublicApp -Force
        }
        catch{
            Write-Error $_
        }
    }
    End{
        return $newApplication
    }
}

