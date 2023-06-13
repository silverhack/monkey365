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

Function Invoke-Monkey365{
    <#
        .SYNOPSIS
            Monkey365 is a multi-threaded plugin-based tool to help assess the security of both Azure Cloud and Microsoft 365 environment configurations.
            This module will not change any asset deployed in cloud. Only GET and POST HTTP requests are made to the API endpoints.

        .DESCRIPTION
            The main features included in this version are:

	        Return a number of attributes on computers, users, configurations from Azure Active Directory
            Review of Azure AD configuration
	        Search for High level accounts in both Azure and Microsoft 365, including Azure Active Directory, classic administrators and Directory Roles (RBAC)
	        Multi-Threading support
	        Plugin Support
            The following Azure services are supported by Monkey365:
                Azure SQL Databases
                Azure MySQL Databases
                Azure PostgreSQL Databases
                Azure Active Directory
                Storage Accounts
                Classic Virtual Machines
                Virtual Machines V2
                Security Status
                Security Policies
                Role Assignments (RBAC)
                Security Patches
                Security Baseline
                Microsoft Defender for Cloud
                Network Security Groups
                Classic Endpoints
                Azure Security Alerts
                Azure Web Application Firewall
                Azure Application services
            The following Microsoft 365 applications are supported by Monkey365:
                Exchange Online
                Microsoft Teams
                SharePoint Online
                OneDrive for Business

            With Monkey365, there is also support for exporting data driven to popular formats like CSV, XML or JSON.

            Office Support
            Support for exporting data driven to EXCEL format. The tool also support table style modification, chart creation, company logo or independent language support. At the moment Office Excel 2010, Office Excel 2013 and Office Excel 2016 are supported by the tool.
            Note: EXCEL application must be installed on machine.

            .NOTES
	            Author		: Juan Garrido
                Twitter		: @tr1ana
                File Name	: Invoke-Monkey365.ps1
                Version     : 0.8.5-beta

            .LINK
                https://github.com/silverhack/monkey365

        .EXAMPLE
	        $assets = Invoke-Monkey365 -ExportTo PRINT -PromptBehavior SelectAccount -IncludeAzureAD -Instance Microsoft365 -Analysis SharePointOnline

            This example retrieves information of both Azure AD and SharePoint Online and print results. If credentials are not supplied, Monkey365 will prompt for credentials.

        .EXAMPLE
	        $data = Invoke-Monkey365 -PromptBehavior SelectAccount -Instance Azure -Analysis All -subscriptions 00000000-0000-0000-0000-000000000000 -TenantID 00000000-0000-0000-0000-000000000000 -ExportTo PRINT

            This example retrieves information of an Azure subscription and prints results to a local variable. If credentials are not supplied, Monkey365 will prompt for credentials.

        .EXAMPLE
	        Invoke-Monkey365 -ClientId 00000000-0000-0000-0000-000000000000 -ClientSecret ("MySuperClientSecret" | ConvertTo-SecureString -AsPlainText -Force) -Instance Azure -Analysis All -subscriptions 00000000-0000-0000-0000-000000000000 -TenantID 00000000-0000-0000-0000-000000000000 -ExportTo CLIXML,EXCEL,CSV,JSON,HTML

            This example retrieves information of an Azure subscription and will export data driven to CSV, JSON, HTML, XML and Excel format into monkey-reports folder. The script will connect to Azure using the client credential flow.

        .EXAMPLE
            Invoke-Monkey365 -certificate C:\monkey365\testapp.pfx -ClientId 00000000-0000-0000-0000-000000000000 -CertFilePassword ("MySuperCertSecret" | ConvertTo-SecureString -AsPlainText -Force) -Instance Microsoft365 -Analysis SharePointOnline -TenantID 00000000-0000-0000-0000-000000000000 -ExportTo CLIXML,EXCEL,CSV,JSON,HTML
	        This example retrieves information of an Microsoft 365 subscription and will export data driven to CSV, JSON, HTML, XML and Excel format into monkey-reports folder. The script will connect to Azure using the certificate credential flow.

        .EXAMPLE
	        Invoke-Monkey365 -PromptBehavior SelectAccount -Instance Azure -Analysis All -TenantID 00000000-0000-0000-0000-000000000000 -ExportTo HTML

            This example retrieves information of an Azure subscription and will export data driven to HTML format into monkey-reports folder. If credentials are not supplied, Monkey365 will prompt for credentials.

        .PARAMETER Environment
	        Select an Environment of Azure services. Valid options are AzureCloud, Preproduction, China, AzureUSGovernment. Default value is AzureCloud

        .PARAMETER Instance
	        Select the instance to scan. Valid options are Azure or Microsoft365

        .PARAMETER Analysis
	        Collect data from specified assets. Depending of what instance was selected, the following values are accepted:

            Value                        Description
            ActiveDirectory              Retrieves information from Azure Active Directory, including users, groups, contacts, policies, reports, administrative users, etc..
            SharePointOnline             Retrieves information from SharePoint Online, including lists, users, groups, orphaned users, etc..
            ExchangeOnline               Retrieves information from Exchange Online
            Databases                    Retrieves information from Azure SQL, including databases, Transparent Data Encryption or Threat Detection Policy
            VirtualMachines              Retrieves information from virtual machines deployed on both classic mode and resource manager.
            SecurityAlerts               Get Security Alerts from Microsoft Azure.
            SecurityCenter               Get information about Microsoft Defender for Cloud
            RoleAssignments              Retrieves information about RBAC Users and Groups
            StorageAccounts              Retrieves information about storage accounts deployed on Classic mode and resource manager
            All                          Extract all information about an Azure subscription

        .PARAMETER ExportTo
	        Export data driven to specific formats. Accepted values are CSV, JSON, XML, PRINT, EXCEL, HTML.

        .PARAMETER ExcludedResources
	        Exclude unwanted azure resources from being scanned

        .PARAMETER ExcludePlugin
	        Exclude plugins from being executed

        .PARAMETER Threads
	        Change the threads settings. By default, a large number of requests will be made with two threads

        .PARAMETER ForceAuth
	        Force Monkey365 to Authenticate. Only valid for legacy user & password authentication

        .PARAMETER user_credentials
	        pscredential of the user requesting the token

        .PARAMETER ClearCache
	        Clear Token Cache. Only valid if module is using ADAL library

        .PARAMETER WriteLog
	        Write events to a log file

        .PARAMETER TenantID
	        Force to authenticate to specific tenant

        .PARAMETER AuditorName
	        Auditor Name. Used in Excel File

        .PARAMETER ClientId
	        Service Principal Application ID. Used in Certificate and Client credentials authentication flow

        .PARAMETER ClientSecret
	        Secret password. Used in Client credentials authentication flow

        .PARAMETER Certificate
	        PFX certificate file. Used in Certificate authentication flow

        .PARAMETER CertFilePassword
	        PFX certificate password. Used in Certificate authentication flow

        .PARAMETER DeviceCode
            Authenticate by using device code authentication flow
    #>
    [CmdletBinding(HelpUri='https://silverhack.github.io/monkey365/')]
    Param (
        # pscredential of the user requesting the token
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [System.Management.Automation.PSCredential] $user_credentials,

        [parameter(Mandatory= $false, ParameterSetName = 'Implicit', HelpMessage= "User for access to the O365 services")]
        [String]$UserPrincipalName,

        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [string] $TenantId,

        [parameter(Mandatory= $false, HelpMessage= "Select an instance of Azure services")]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic",

        [Parameter(Mandatory=$false)]
        [ValidateSet('Azure','Microsoft365')]
        $Instance,

        [Parameter(Mandatory=$false, HelpMessage="Clear token cache")]
        [Switch]
        $IncludeAzureAD,

        [Parameter(HelpMessage="Save entire project")]
        [Switch]
        $SaveProject,

        [Parameter(HelpMessage="Import Monkey 365 Job")]
        [Switch]$ImportJob,

        [Parameter(Mandatory=$false, HelpMessage="Plugins to exclude")]
        [string[]]$ExcludePlugin,

        [parameter(Mandatory= $false, HelpMessage= "Export data to multiple formats")]
        [ValidateSet("CSV","JSON","CLIXML","PRINT","EXCEL", "HTML")]
        [Array]$ExportTo=@(),

        [Parameter(Mandatory= $false, HelpMessage = 'Please specify folder to export results')]
        [System.IO.DirectoryInfo]$OutDir,

        [Parameter(Mandatory=$false, HelpMessage="Change the threads settings. Default is 2")]
        [int32]
        $Threads = 2,

        [Parameter(Mandatory=$false, HelpMessage="Clear token cache")]
        [Switch]
        $ClearCache,

        [Parameter(Mandatory= $false, HelpMessage="Auditor Name. Used in Excel File")]
	    [String] $AuditorName = $env:username,

        [Parameter(Mandatory= $false, HelpMessage="Resolve Tenant domain name")]
	    [String] $ResolveTenantDomainName,

        [Parameter(Mandatory= $false, HelpMessage="Resolve Tenant user name")]
	    [String] $ResolveTenantUserName,

        [Parameter(Mandatory=$false, HelpMessage="Write Log file")]
        [Switch]
        $WriteLog=$false,

        [parameter(Mandatory= $false, HelpMessage= "json file with all rules")]
        [ValidateScript({
                        if( -Not (Test-Path -Path $_) ){
                            throw ("The ruleset does not exist in {0}" -f (Split-Path -Path $_))
                        }
                        if(-Not (Test-Path -Path $_ -PathType Leaf) ){
                            throw "The ruleSet argument must be a json file. Folder paths are not allowed."
                        }
                        if($_ -notmatch "(\.json)"){
                            throw "The file specified in the ruleset argument must be of type json"
                        }
                        return $true
        })]
        [System.IO.FileInfo]$RuleSet,

        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-File')]
        [string]$ClientId,

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-App')]
        [securestring]$ClientSecret,

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
        [Security.SecureString]$CertFilePassword,

        # location where the authorization server will sends the user once is authenticated.
        [Parameter(Mandatory = $false)]
        [uri]$RedirectUri,

        # Indicates whether AcquireToken should automatically prompt only if necessary or whether it should prompt regardless of whether there is a cached token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [ValidateSet("Always", "Auto", "Never", "RefreshSession","SelectAccount")]
        [String]$PromptBehavior = 'Auto',

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Force Authentication Context. Only valid for user&password auth method")]
        [Switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Force silent authentication")]
        [Switch]$Silent,

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Device code authentication")]
        [Switch]$DeviceCode
    )
    dynamicparam{
        # Set available instance class
        $instance_class = @{
            Azure = $Script:azure_plugins
            Microsoft365 = $Script:m365_plugins
        }
        # set a new dynamic parameter
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        # check to see whether the user already chose an instance
        if(Get-Variable -Name Instance -ErrorAction Ignore){
            $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $analysis_attr_name = New-Object System.Management.Automation.ParameterAttribute
            $analysis_attr_name.Mandatory = $true
            $attributeCollection.Add($analysis_attr_name)

            # set the ValidateSet attribute
            $token_attr_name = New-Object System.Management.Automation.ValidateSetAttribute($instance_class.$Instance)
            $attributeCollection.Add($token_attr_name)

            # create the dynamic -Analysis parameter
            $analysis_pname = 'Analysis'
            $analysis_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($analysis_pname,
            [Array], $attributeCollection)
            $paramDictionary.Add($analysis_pname, $analysis_type_dynParam)
        }
        #Add parameters for Azure instance
        if($null -ne (Get-Variable -Name Instance -ErrorAction Ignore) -and $Instance -eq 'Azure'){
            #Create the -AllSubscriptions switch parameter
            $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $all_sbs_attr_name = New-Object System.Management.Automation.ParameterAttribute
            $all_sbs_attr_name.Mandatory = $false
            $attributeCollection.Add($all_sbs_attr_name)

            #Create alias for -AllSubscriptions switch param
            $allsbs_alias = New-Object System.Management.Automation.AliasAttribute -ArgumentList 'all_subscriptions'
            $attributeCollection.Add($allsbs_alias)

            $sbs_pname = 'AllSubscriptions'
            $analysis_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($sbs_pname,
            [switch], $attributeCollection)
            $paramDictionary.Add($sbs_pname, $analysis_type_dynParam)

            #Create the -Subscriptions string parameter
            $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $sbs_attr_name = New-Object System.Management.Automation.ParameterAttribute
            $sbs_attr_name.Mandatory = $false
            $attributeCollection.Add($sbs_attr_name)

            $sbs_pname = 'Subscriptions'
            $analysis_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($sbs_pname,
            [string], $attributeCollection)
            $paramDictionary.Add($sbs_pname, $analysis_type_dynParam)

            #Create the -ResourceGroups string parameter
            $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $rg_attr_name = New-Object System.Management.Automation.ParameterAttribute
            $rg_attr_name.Mandatory = $false
            $attributeCollection.Add($rg_attr_name)

            $rg_pname = 'ResourceGroups'
            $rg_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($rg_pname,
            [String[]], $attributeCollection)
            $paramDictionary.Add($rg_pname, $rg_type_dynParam)

            #Create the -ExcludeResources File parameter
            $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $exclude_rsrc_attr_name = New-Object System.Management.Automation.ParameterAttribute
            $exclude_rsrc_attr_name.Mandatory = $false
            $attributeCollection.Add($exclude_rsrc_attr_name)

            $rsrc_pname = 'ExcludedResources'
            $rsrc_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($rsrc_pname,
            [System.IO.FileInfo], $attributeCollection)
            $paramDictionary.Add($rsrc_pname, $rsrc_type_dynParam)
        }
        #Add parameters for Microsoft365 instance
        if($null -ne (Get-Variable -Name Instance -ErrorAction Ignore) -and $Instance -eq 'Microsoft365'){
            #Create the -ScanSites string parameter
            $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $rg_attr_name = New-Object System.Management.Automation.ParameterAttribute
            $rg_attr_name.Mandatory = $false
            $attributeCollection.Add($rg_attr_name)
            $rg_pname = 'ScanSites'
            $rg_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($rg_pname,
            [string[]], $attributeCollection)
            $paramDictionary.Add($rg_pname, $rg_type_dynParam)
        }
        # return the collection of dynamic parameters
        $paramDictionary
    }
    Begin{
        #Set Window name
        $Host.UI.RawUI.WindowTitle = "Monkey 365 Security Scanner"
        #Start Time
        $starttimer = Get-Date
        #####Get Default parameters ########
        $MyParams = $PSBoundParameters
        ################### Validate parameters #########################
        $MyParams = Initialize-MonkeyParameter -MyParams $MyParams
        ################### End Validate parameters #####################
        Initialize-MonkeyVar -MyParams $MyParams
        #Create O365 object
        New-O365Object
        #Set timer
        $O365Object.startDate = $starttimer
        Update-PsObject
        #Initialize Logger
        Initialize-MonkeyLogger
        #Resolve tenant
        if($MyParams.ResolveTenantDomainName){
            $msg = @{
                MessageData = "Getting public tenant information";
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $script:InformationAction;
                Tags = @('Monkey365ResolveTenant');
            }
            Write-Information @msg
            Get-PublicTenantInformation -Domain $ResolveTenantDomainName
            return
        }
        if($MyParams.ResolveTenantUserName){
            $msg = @{
                MessageData = "Getting public tenant information";
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $script:InformationAction;
                Tags = @('Monkey365ResolveTenant');
            }
            Write-Information @msg
            Get-PublicTenantInformation -Username $ResolveTenantUserName
            return
        }
        #Check if import job
        if($PSBoundParameters.ContainsKey('ImportJob') -and $PSBoundParameters.ImportJob){
            Import-MonkeyJob
            return
        }
        #Get Environment
        $O365Object.Environment = Get-MonkeyEnvironment -Environment $MyParams.Environment;
        #Initialize authentication parameters
        Initialize-AuthenticationParam
        #Connect
        Connect-MonkeyCloud
    }
    Process{
        if(($PSBoundParameters.ContainsKey('ImportJob') -and $null -eq $PSBoundParameters['ImportJob']) -and $null -ne $O365Object.Instance){
            switch ($O365Object.Instance.ToLower()){
                'azure'{
                    Invoke-AzureScanner
                }
                'microsoft365'{
                    Invoke-M365Scanner
                }
                'azuread'{
                    Invoke-AzureADScanner
                }
                default{
                    throw ("{0}" -f "Unable to recognize {0} environment",$O365Object.Instance.ToLower())
                }
            }
        }
    }
    End{
        #Stop timer
        $stoptimer = Get-Date
        $elapsedTime =  [math]::round(($stoptimer - $starttimer).TotalMinutes , 2)
        $msg = @{
            MessageData = ($message.TimeElapsedScript -f $elapsedTime);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $script:InformationAction;
            Tags = @('Monkey365ScriptFinished');
        }
        Write-Information @msg
        #Stopping sessions
        Remove-MonkeyPsSession
        #Clean runspaces
        if($null -ne $O365Object.monkey_runspacePool -and $O365Object.monkey_runspacePool -is [System.Management.Automation.Runspaces.RunspacePool]){
            $O365Object.monkey_runspacePool.Dispose()
        }
        #Start Watcher
        if($null -ne (Get-Command -Name "Watch-AccessToken" -ErrorAction ignore)){
            Watch-AccessToken -Stop
        }
        #Stop timer
        $O365Object.Timer.stop()
        $O365Object.Timer.dispose()
        #Stop loggers
        Stop-Logger
        #collect garbage
        [System.GC]::GetTotalMemory($true) | out-null
    }
}