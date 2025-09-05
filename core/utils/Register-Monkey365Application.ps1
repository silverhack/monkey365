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

Function Register-Monkey365Application {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Register-Monkey365Application
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false, HelpMessage= "TenantId")]
        [string] $TenantId,

        [parameter(Mandatory= $false, HelpMessage= "Select an instance of Azure services")]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic",

        [Parameter(Mandatory = $true, HelpMessage= "Select an instance of Microsoft365 services")]
        [ValidateSet('SharePointOnline','ExchangeOnline','MicrosoftTeams','MicrosoftGraph')]
        [String[]]$Services,

        # ClientAssertionCertificate of the application requesting the token
        [Parameter(Mandatory = $false, HelpMessage = 'Certificate in crt format')]
        [ValidateScript(
            {
            if( -Not ($_ | Test-Path) ){
                throw ("The cert file does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The argument must be a PFX file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.cer)"){
                throw "The certificate specified argument must be of type crt"
            }
            return $true
        })]
        [System.IO.FileInfo]$Certificate,

        # Secure password of the certificate
        [Parameter(Mandatory = $false, HelpMessage = 'Certificate password')]
        [System.String]$CertFilePassword,

        # Certificate years valid
        [Parameter(Mandatory = $false, HelpMessage = 'Certificate years')]
        [System.Int32]$CertYearsValid = 2
    )
    Begin{
        $Verbose = $False;
        $InformationAction = 'SilentlyContinue'
        If($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        If($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        #####Get Default parameters ########
        $MyParams = $PSBoundParameters
        #Create O365 object
        New-O365Object
        #Set graph filter
        $filter = [uri]::EscapeDataString("displayName eq 'monkey365'")
        # Set null
        $certFile = $monkeyApp = $sp = $null;
        #Set auth object
        $msAuthObject = @{
            msGraphToken = $null
            me = $null;
        }
        #Set application object
        $monkey365App = [PsCustomObject]@{
            displayName = $null;
            id = $null;
            clientId = $null;
            homePage  = $null;
            servicePrincipalId = $null;
        }
        #Set description
        $description = "Monkey365 is an Open Source security tool that can be used to easily conduct not only Microsoft 365, but also Azure subscriptions and Microsoft Entra ID security configuration reviews without the significant overhead of learning tool APIs or complex admin panels from the start.";
        #Set application Type
        $ApplicationType = "Role"
        #Set logo
        $logo = ("{0}{1}images{2}MonkeyLogo.png" -f $O365Object.Localpath,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
        #Set list for applications
        $requiredResourceAccessList = [System.Collections.Generic.List[System.Collections.Hashtable]]::new()
        #Set list for role assignments
        $requiredRoleList = [System.Collections.Generic.List[System.String]]::new();
        $MSAL = ("{0}{1}core/modules/monkeymsal" -f $O365Object.Localpath,[System.IO.Path]::DirectorySeparatorChar)
        Import-Module $MSAL -Scope Global -Force
        $msalAppMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-MonkeyMsalApplication")
        #Set new dict
        $newPsboundParams = [ordered]@{}
        $param = $msalAppMetadata.Parameters.Keys
        foreach($p in $param.GetEnumerator()){
            if($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters.Item($p)){
                If($p.toLower() -eq 'certificate' -or $p.toLower() -eq 'CertFilePassword'){continue}
                $newPsboundParams.Add($p,$PSBoundParameters.Item($p))
            }
        }
        #Create new application
        $newApplication = New-MonkeyMsalApplication @newPsboundParams
        #Authenticate to Microsoft Graph
        $p = @{
            PublicApp = $newApplication;
            Resource = $O365Object.Environment.Graphv2;
            InformationAction = $InformationAction;
            Verbose = $Verbose;
        }
        $msAuthObject.msGraphToken = Get-MonkeyMSALToken @p
        #Add graph token to object
        $O365Object.auth_tokens.MSGraph = $msAuthObject.msGraphToken;
        If($msAuthObject.msGraphToken){
            $p = @{
                InformationAction = $InformationAction;
                Verbose = $Verbose;
            }
            $msAuthObject.me = Get-MonkeyMe @p
        }
        #Set applications
        $applications = @{
            MicrosoftGraph = '00000003-0000-0000-c000-000000000000';
            ExchangeOnline = '00000002-0000-0ff1-ce00-000000000000';
            SharePointOnline = '00000003-0000-0ff1-ce00-000000000000';
        }
        #Set permissions
        $permissions = @{
            MicrosoftGraph = @{
                resourceAppId = $applications.Item('MicrosoftGraph');
                resourceAccess = @{
                    "Group.Read.All" = "5b567255-7703-4780-807c-7be8301ae99b"
                    "User.Read.All" = "df021288-bdef-4463-88db-98f22de89214"
                    "Directory.Read.All" = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
                    "Organization.Read.All" = "498476ce-e0fe-48b0-b801-37ba7e2685c6"
                    "Policy.Read.All" = "246dd0d5-5bd0-4def-940b-0421030a5b68"
                    "RoleManagement.Read.Directory" = "483bed4a-2ad3-4361-a73b-c83ccdbdc53c"
                    "GroupMember.Read.All" = "98830695-27a2-44f7-8c18-0c3ebc9698f6"
                    "PrivilegedAccess.Read.AzureADGroup" = "01e37dc9-c035-40bd-b438-b2879c4870a6"
                    "PrivilegedEligibilitySchedule.Read.AzureADGroup" = "edb419d6-7edc-42a3-9345-509bfdf5d87c"
                    "RoleManagementPolicy.Read.AzureADGroup" = "69e67828-780e-47fd-b28c-7b27d14864e6"
                    "SecurityEvents.Read.All" = "bf394140-e372-4bf9-a898-299cfc7564e5"
                    "IdentityRiskEvent.Read.All" = "6e472fd1-ad78-48da-a0f0-97ab2c6b769e"
                    "Application.Read.All" = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
                    "UserAuthenticationMethod.Read.All" = "38d9df27-64da-44fd-b7c5-a6fbac20248f"
                }
            }
            MicrosoftTeams = @{
                resourceAppId = $applications.Item('MicrosoftGraph');
                resourceAccess = @{
                    "AppCatalog.Read.All" = "e12dae10-5a57-4817-b79d-dfbec5348930"
                    "Channel.ReadBasic.All" = "59a6b24b-4225-4393-8165-ebaec5f55d7a"
                    "ChannelMember.Read.All" = "3b55498e-47ec-484f-8136-9013221c06a9"
                    "ChannelSettings.Read.All" = "c97b873f-f59f-49aa-8a0e-52b32d762124"
                    "TeamSettings.Read.All" = "242607bd-1d2c-432c-82eb-bdb27baa23ab"
                }
            }
            ExchangeOnline = @{
                resourceAppId = $applications.Item('ExchangeOnline');
                resourceAccess = @{
                    "Exchange.ManageAsApp" = "dc50a0fb-09a3-484d-be87-e023b12c6440"
                }
            }
            SharePointOnline = @{
                resourceAppId = $applications.Item('SharePointOnline');
                resourceAccess = @{
                    "Sites.FullControl.All" = "678536fe-1083-478a-9c59-b99265e6b0d3"
                }
            }
        }
        #Role assignment
        $roleTemplate = @{
            ExchangeAdministrator = '29232cdf-9323-42fd-ade2-1d097af3e4de';
            GlobalReader = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
            SharePointAdministrator = 'f28a1f50-f6e7-4571-818b-6a12f2af6b6c'
        }
        $roleAssignment = @{
            MicrosoftTeams = $roleTemplate.Item('GlobalReader');
            ExchangeOnline = $roleTemplate.Item('GlobalReader');
            SharePointOnline = $roleTemplate.Item('SharePointAdministrator');
        }
        #Check if certificate must be generated
        If($PSBoundParameters.ContainsKey('Certificate') -and $PSBoundParameters['Certificate']){
            Try{
                $certFile = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($PSBoundParameters['Certificate'].FullName)
                If ($certFile.NotAfter -lt (Get-Date)){
                    Write-Warning ("Certificate {0} is expired" -f $PSBoundParameters['Certificate'].FullName)
                    throw ("[MonkeyApplicationError] {0}" -f "Expired Certificate")
                }
            }
            Catch{
                throw ("[MonkeyApplicationError] {0}: {1}" -f "Unable to register Monkey365 application",$_.Exception.Message)
            }
        }
        Else{
            Try{
                #Get temp path
                $_path = [System.IO.Path]::GetTempPath()
                # Generate a new RSA key pair
                $rsa = [System.Security.Cryptography.RSA]::Create();
                $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
                    "CN=monkey365",
                    $rsa,
                    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
                );
                $certFile = $request.CreateSelfSigned([System.DateTimeOffset]::UtcNow, [System.DateTimeOffset]::UtcNow.AddYears($CertYearsValid));
                $certFileFullPath = ("{0}{1}monkey.cer" -f $_path,[System.IO.Path]::DirectorySeparatorChar)
                $bytes = $certFile.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                [System.IO.File]::WriteAllBytes($certFileFullPath,$bytes)
                Write-Host ("New CRT certificate created {0}" -f $certFileFullPath) -ForegroundColor Green
                If($PSBoundParameters.ContainsKey('CertFilePassword') -and $PSBoundParameters['CertFilePassword']){
                    $bytes = $certFile.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $PSBoundParameters['CertFilePassword']);
                }
                Else{
                    $bytes = $certFile.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx);
                }
                $pfxFullPath = ("{0}{1}monkey.pfx" -f $_path,[System.IO.Path]::DirectorySeparatorChar)
                [System.IO.File]::WriteAllBytes($pfxFullPath,$bytes)
                Write-Host ("New PFX certificate created {0}" -f $pfxFullPath) -ForegroundColor Green
            }
            Catch{
                throw ("[MonkeyApplicationError] {0}: {1}" -f "Unable to register Monkey365 application",$_.Exception.Message)
            }
        }
    }
    Process{
        If($msAuthObject.me -and $null -ne $certFile){
            #Set Auth header
            $AuthHeader = @{
                Authorization = $msAuthObject.msGraphToken.CreateAuthorizationHeader();
            }
            #Iterate for each service
            ForEach($service in $PSBoundParameters['Services'].GetEnumerator()){
                Write-Host ("Add permissions for {0}" -f $service) -ForegroundColor Green
                $perms = $permissions.Item($service);
                If($perms){
                    $resourceAppId = $perms.resourceAppId;
                    If($requiredResourceAccessList.Where({$_.resourceAppId -eq $resourceAppId}).Count -gt 0){
                        #Get resourceAccessList
                        $resourceAccessList = $requiredResourceAccessList | Where-Object {$_.resourceAppId -eq $resourceAppId}
                        ForEach($p in $perms.resourceAccess.GetEnumerator()){
                            Write-Host ("Append {0} permission for {1}" -f $p.Name, $service) -ForegroundColor Magenta
                            [void]$resourceAccessList.resourceAccess.Add(
                                @{id = $p.Value;type=$ApplicationType}
                            )
                        }
                    }
                    Else{
                        #Set new resource access list
                        $resourceAccessList = [System.Collections.Generic.List[System.Collections.Hashtable]]::new()
                        ForEach($p in $perms.resourceAccess.GetEnumerator()){
                            Write-Host ("Append {0} permission for {1}" -f $p.Name, $service) -ForegroundColor Magenta
                            [void]$resourceAccessList.Add(
                                @{id = $p.Value;type=$ApplicationType}
                            )
                        }
                        #Set new dict for application
                        [void]$requiredResourceAccessList.Add(
                            @{resourceAppId = $resourceAppId;resourceAccess=$resourceAccessList}
                        )
                    }
                }
                #Populate Role assignment
                $rbac = $roleAssignment.Item($service);
                If($rbac){
                    If(-NOT $requiredRoleList.Contains($rbac)){
                        [void]$requiredRoleList.Add($rbac);
                    }
                }
            }
            #Check if monkey365 is already installed
            $monkeyExists = ('{0}/v1.0/applications?$filter={1}' -f $O365Object.Environment.Graphv2,$filter)
            $p = @{
                Url = $monkeyExists;
                Headers = $AuthHeader;
                Method = "GET";
                InformationAction = $InformationAction;
                Verbose = $Verbose;
            }
            #Get dataset info
            $output = Invoke-MonkeyWebRequest @p
            If($output.value.Count -gt 0){
                Write-Host ("The application Monkey365 is already registered") -ForegroundColor Green
                $monkeyApp = $output.value | Select-Object -First 1
                $appUri = ('{0}v1.0/applications/{1}' -f $O365Object.Environment.Graphv2,$monkeyApp.id)
                $body = @{"requiredResourceAccess" = $requiredResourceAccessList} | ConvertTo-Json -Depth 50
                Write-Host "Updating permissions for Monkey365 app" -ForegroundColor Green
                $p = @{
                    Url = $appUri;
                    Headers = $AuthHeader;
                    UserAgent = $O365Object.userAgent;
                    ContentType = 'application/json';
                    Method = "PATCH";
                    Data = $body;
                    Verbose = $Verbose;
                    InformationAction = $InformationAction;
                }
                #Get dataset info
                [void](Invoke-MonkeyWebRequest @p)
                #Update certificate
                $keyCred = @(
                    @{
                        customKeyIdentifier = [System.Convert]::ToBase64String($certFile.GetCertHash());
                        keyId = [System.Guid]::NewGuid().ToString();
                        type = "AsymmetricX509Cert";
                        usage = "Verify";
                        key = [System.Convert]::ToBase64String($certFile.GetRawCertData());
                    };
                );
                $body = @{"keyCredentials" = $keyCred} | ConvertTo-Json -Depth 10
                Write-Host "Updating certificate credentials for Monkey365 app" -ForegroundColor Green
                $p = @{
                    Url = $appUri;
                    Headers = $AuthHeader;
                    UserAgent = $O365Object.userAgent;
                    ContentType = 'application/json';
                    Method = "PATCH";
                    Data = $body;
                    Verbose = $Verbose;
                    InformationAction = $InformationAction;
                }
                #Get dataset info
                [void](Invoke-MonkeyWebRequest @p)
                #Check if service principal exists
                $filter = [uri]::EscapeDataString(("appId eq '{0}'" -f $monkeyApp.appId))
                $spExists = ('{0}/v1.0/servicePrincipals?$filter={1}' -f "https://graph.microsoft.com",$filter)
                $p = @{
                    Url = $spExists;
                    Headers = $AuthHeader;
                    Method = "GET";
                }
                #Get dataset info
                $sp = Invoke-MonkeyWebRequest @p
                If($null -eq $sp){
                    #Create service principal
                    Write-Host ("Create Service Principal for Monkey365 application") -ForegroundColor Green
                    $spUri = ('{0}v1.0/servicePrincipals' -f $O365Object.Environment.Graphv2)
                    $body = @{"appId" = ("{0}" -f $monkeyApp.appId)} | ConvertTo-Json -Depth 10
                    $p = @{
                        Url = $spUri;
                        Headers = $AuthHeader;
                        UserAgent = $O365Object.userAgent;
                        ContentType = 'application/json';
                        Method = "POST";
                        Data = $body;
                        Verbose = $Verbose
                        InformationAction = $InformationAction;
                    }
                    #Execute
                    $sp = Invoke-MonkeyWebRequest @p
                    If($sp){
                        Write-Host ("Service Principal with {0} id was created successfully" -f $sp.id) -ForegroundColor Green
                    }
                }
                Else{
                    $sp = $sp.value | Select-Object -First 1
                }
            }
            Else{
                #Create application
                $body = @{
                    "displayName" = "Monkey365";
                    "description" = $description;
                    "notes" = $description;
                    "signInAudience" = "AzureADMyOrg";
                    "keyCredentials" = @(
                        @{
                            customKeyIdentifier = [System.Convert]::ToBase64String($certFile.GetCertHash());
                            keyId = [System.Guid]::NewGuid().ToString();
                            type = "AsymmetricX509Cert";
                            usage = "Verify";
                            key = [System.Convert]::ToBase64String($certFile.GetRawCertData());
                        };
                    );
                    "requiredResourceAccess" = $requiredResourceAccessList;
                    "web" = @{
                        "redirectUris" = @();
                        "homePageUrl" = "https://silverhack.github.io/monkey365/";
                        "logoutUrl" =  "https://silverhack.github.io/monkey365/assets/images/MonkeyLogo.png";
                        "implicitGrantSettings" =  @{
                            "enableIdTokenIssuance" =  $false;
                            "enableAccessTokenIssuance" = $false;
                        }
                    }
                } | ConvertTo-Json -Depth 100
                #Set param
                $appUri = ("{0}v1.0/applications" -f $O365Object.Environment.Graphv2)
                $p = @{
                    Url = $appUri;
                    Headers = $AuthHeader;
                    UserAgent = $O365Object.userAgent;
                    ContentType = 'application/json';
                    Method = "POST";
                    Data = $body;
                    Verbose = $Verbose;
                    InformationAction = $InformationAction;
                }
                #Get dataset info
                $monkeyApp = Invoke-MonkeyWebRequest @p
                If($null -ne $monkeyApp){
                    Write-Host "Your Monkey365 application was created successfully" -ForegroundColor Green
                    #Add logo
                    Write-Host "Add logo to Monkey365 application" -ForegroundColor Green
                    $logoUri = ("{0}v1.0/applications/{1}/logo" -f $O365Object.Environment.Graphv2,$monkeyApp.id)
                    $p = @{
                        Url = $logoUri;
                        Headers = $AuthHeader;
                        UserAgent = $O365Object.userAgent;
                        ContentType = 'image/png';
                        Method = "PUT";
                        Data = $logo;
                        AsStreamContent = $true;
                        Verbose = $Verbose;
                        InformationAction = $InformationAction;
                    }
                    #Execute
                    $output = Invoke-MonkeyWebRequest @p
                    #Assign owner to application
                    Write-Host ("Assign {0} owner to Monkey365 application" -f $msAuthObject.me.displayName) -ForegroundColor Green
                    $ownerUri = ('{0}v1.0/applications/{1}/owners/$ref' -f $O365Object.Environment.Graphv2,$monkeyApp.id)
                    $body = @{"@odata.id" = ("https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $msAuthObject.me.id)} | ConvertTo-Json -Depth 10
                    $p = @{
                        Url = $ownerUri;
                        Headers = $AuthHeader;
                        UserAgent = $O365Object.userAgent;
                        ContentType = 'application/json';
                        Method = "POST";
                        Data = $body;
                        Verbose = $Verbose
                        InformationAction = $InformationAction;
                    }
                    #Execute
                    [void](Invoke-MonkeyWebRequest @p)
                    #Create service principal
                    Write-Host ("Create Service Principal for Monkey365 application") -ForegroundColor Green
                    $spUri = ('{0}v1.0/servicePrincipals' -f $O365Object.Environment.Graphv2)
                    $body = @{"appId" = ("{0}" -f $monkeyApp.appId)} | ConvertTo-Json -Depth 10
                    $p = @{
                        Url = $spUri;
                        Headers = $AuthHeader;
                        UserAgent = $O365Object.userAgent;
                        ContentType = 'application/json';
                        Method = "POST";
                        Data = $body;
                        Verbose = $Verbose
                        InformationAction = $InformationAction;
                    }
                    #Execute
                    $sp = Invoke-MonkeyWebRequest @p
                    If($sp){
                        Write-Host ("Service Principal with {0} id was created successfully" -f $sp.id) -ForegroundColor Green
                    }
                }
            }
            If($null -ne $monkeyApp -and $null -ne $sp){
                If($requiredRoleList.Count -gt 0){
                    Write-Host ("Assigning roles to Service Principal {0}" -f $sp.id) -ForegroundColor Green
                    #Get actual member Of
                    $memberOf = ('{0}/v1.0/servicePrincipals/{1}/transitiveMemberOf' -f "https://graph.microsoft.com",$sp.id)
                    $p = @{
                        Url = $memberOf;
                        Headers = $AuthHeader;
                        Method = "GET";
                        Verbose = $Verbose
                        InformationAction = $InformationAction;
                    }
                    #Get dataset info
                    $_object = Invoke-MonkeyWebRequest @p
                    If($null -ne $_object){
                        $actualRoles = $_object.value.Where({$_.'@odata.type' -eq '#microsoft.graph.directoryRole'}) | Select-Object -ExpandProperty roleTemplateId -ErrorAction Ignore
                    }
                    ForEach($roleId in $requiredRoleList.GetEnumerator()){
                        If(@($actualRoles).Contains($roleId)){
                            Write-Host ("Service Principal {0} is already member of {1}" -f $sp.id, $roleTemplate.GetEnumerator().Where({$_.Value -eq $roleId}).Name) -ForegroundColor Green
                        }
                        Else{
                            Write-Host ("Assign {0} to service principal {1}" -f $roleTemplate.GetEnumerator().Where({$_.Value -eq $roleId}).Name, $sp.id) -ForegroundColor Green
                            $postData = @{
                                "@odata.type" = "#microsoft.graph.unifiedRoleAssignment";
                                "principalId" = $sp.id;
                                "roleDefinitionId" = $roleId;
                                "directoryScopeId" = "/";
                            } | ConvertTo-Json -Depth 10
                            $ra = ('{0}/v1.0/roleManagement/directory/roleAssignments' -f $O365Object.Environment.Graphv2)
                            $p = @{
                                Url = $ra;
                                Headers = $AuthHeader;
                                Method = "POST";
                                ContentType = 'application/json';
                                Data = $postData;
                                Verbose = $Verbose
                                InformationAction = $InformationAction;
                            }
                            #Get dataset info
                            [void](Invoke-MonkeyWebRequest @p)
                        }
                    }
                }
                $monkey365App = [PsCustomObject]@{
                    displayName = $monkeyApp.displayName;
                    id = $monkeyApp.id;
                    clientId = $monkeyApp.appId;
                    homePage  = $monkeyApp.web.homePageUrl;
                    servicePrincipalId = $sp.id;
                }
                Write-Output $monkey365App
            }
        }
    }
}