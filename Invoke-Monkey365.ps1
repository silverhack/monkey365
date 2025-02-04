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
            Monkey365 is a multi-threaded collector-based tool to help assess the security of both Azure Cloud and Microsoft 365 environment configurations.
            This module will not change any asset deployed in cloud. Only GET and POST HTTP requests are made to the API endpoints.

        .DESCRIPTION
            The main features included in this version are:

	        Return a number of attributes on computers, users, configurations from Microsoft Entra ID
            Review of Microsoft Entra ID configuration
	        Search for High level accounts in both Azure and Microsoft 365, including Microsoft Entra ID, classic administrators and Directory Roles (RBAC)
	        Multi-Threading support
	        Collector Support
            The following Azure services are supported by Monkey365:
                Azure SQL Databases
                Azure MySQL Databases
                Azure PostgreSQL Databases
                Microsoft Entra ID
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

            With Monkey365, there is also support for exporting data driven to popular formats like CSV, CLIXML or JSON.

            .NOTES
	            Author		: Juan Garrido
                Twitter		: @tr1ana
                File Name	: Invoke-Monkey365.ps1
                Version     : 0.8.5-beta

            .LINK
                https://github.com/silverhack/monkey365

        .EXAMPLE
	        $assets = Invoke-Monkey365 -ExportTo CSV -PromptBehavior SelectAccount -IncludeEntraID -Instance Microsoft365 -Collect SharePointOnline

            This example will collect information of both Azure AD and SharePoint Online and will save results into a CSV file. If credentials are not supplied, Monkey365 will prompt for credentials.

        .EXAMPLE
	        Invoke-Monkey365 -PromptBehavior SelectAccount -Instance Azure -Collect All -subscriptions 00000000-0000-0000-0000-000000000000 -TenantID 00000000-0000-0000-0000-000000000000 -ExportTo CLIXML

            This example will collect information of an Azure subscription and will export data to a XML-based file. If credentials are not supplied, Monkey365 will prompt for credentials.

        .EXAMPLE
	        Invoke-Monkey365 -ClientId 00000000-0000-0000-0000-000000000000 -ClientSecret ("MySuperClientSecret" | ConvertTo-SecureString -AsPlainText -Force) -Instance Azure -Collect All -subscriptions 00000000-0000-0000-0000-000000000000 -TenantID 00000000-0000-0000-0000-000000000000 -ExportTo CLIXML,CSV,JSON,HTML

            This example retrieves information of an Azure subscription and will export data driven to CSV, JSON, HTML, XML and Excel format into monkey-reports folder. The script will connect to Azure using the client credential flow.

        .EXAMPLE
            Invoke-Monkey365 -certificate C:\monkey365\testapp.pfx -ClientId 00000000-0000-0000-0000-000000000000 -CertFilePassword ("MySuperCertSecret" | ConvertTo-SecureString -AsPlainText -Force) -Instance Microsoft365 -Collect SharePointOnline -TenantID 00000000-0000-0000-0000-000000000000 -ExportTo CLIXML,CSV,JSON,HTML
	        This example retrieves information of an Microsoft 365 subscription and will export data driven to CSV, JSON, HTML, XML and Excel format into monkey-reports folder. The script will connect to Azure using the certificate credential flow.

        .EXAMPLE
	        Invoke-Monkey365 -PromptBehavior SelectAccount -Instance Azure -Collect All -TenantID 00000000-0000-0000-0000-000000000000 -ExportTo HTML

            This example retrieves information of an Azure subscription and will export data driven to HTML format into monkey-reports folder. If credentials are not supplied, Monkey365 will prompt for credentials.

        .PARAMETER Environment
	        Select an Environment of Azure services. Valid options are AzureCloud, Preproduction, China, AzureUSGovernment. Default value is AzureCloud

        .PARAMETER Instance
	        Select the instance to scan. Valid options are Azure or Microsoft365

        .PARAMETER Collect
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
	        Export data driven to specific formats. Accepted values are CSV, JSON, XML, HTML.

        .PARAMETER ExcludedResources
	        Exclude unwanted azure resources from being scanned

        .PARAMETER ExcludeCollector
	        Exclude collectors from being executed

        .PARAMETER Threads
	        Change the threads settings. By default, a large number of requests will be made with two threads

        .PARAMETER ForceAuth
	        Force Monkey365 to Authenticate. Only valid for legacy user & password authentication

        .PARAMETER UserCredentials
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'Implicit', HelpUri='https://silverhack.github.io/monkey365/')]
    Param (
        # pscredential of the user requesting the token
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit-PublicApplication')]
        [Alias('user_credentials')]
        [System.Management.Automation.PSCredential]$UserCredentials,

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
        [String]$Instance,

        [Parameter(Mandatory=$false, HelpMessage="Include Azure AD")]
        [Switch]$IncludeEntraID,

        [Parameter(HelpMessage="Save entire project")]
        [Switch]$SaveProject,

        [Parameter(HelpMessage="Import Monkey 365 Job")]
        [Switch]$ImportJob,

        [Parameter(Mandatory=$false, HelpMessage="Collectors to exclude")]
        [string[]]$ExcludeCollector,

        [parameter(Mandatory= $false, HelpMessage= "Export data to multiple formats")]
        [ValidateSet("CSV","JSON","CLIXML","HTML")]
        [Array]$ExportTo=@(),

        [Parameter(HelpMessage="Compress Monkey365 output to a ZIP file")]
        [Switch]$Compress,

        [Parameter(Mandatory= $false, HelpMessage = 'Please specify folder to export results')]
        [System.IO.DirectoryInfo]$OutDir,

        [Parameter(Mandatory=$false, HelpMessage="Change the threads settings. Default is 2")]
        [int32]$Threads = 2,

        [Parameter(Mandatory=$false, HelpMessage="Clear token cache")]
        [Switch]$ClearCache,

        [Parameter(Mandatory= $false, HelpMessage="Auditor Name. Used in Excel File")]
	    [String] $AuditorName = $env:username,

        [Parameter(Mandatory=$false, HelpMessage="Write Log file")]
        [Switch]$WriteLog,

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
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-InputObject', HelpMessage = 'PsCredential')]
        [Alias('client_credentials')]
        [System.Management.Automation.PSCredential]$ClientCredentials,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate,

        # ClientAssertionCertificate of the application requesting the token
        [Parameter(Mandatory = $false,ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Certificate')]
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
        [System.IO.FileInfo]$Certificate,

        # Secure password of the certificate
        [Parameter(Mandatory = $false,ParameterSetName = 'ClientAssertionCertificate-File', HelpMessage = 'Certificate password')]
        [Security.SecureString]$CertFilePassword,

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

        [parameter(Mandatory= $false, HelpMessage= "Directory with all rules")]
        [ValidateScript({
            if( -Not (Test-Path -Path $_) ){
                throw ("The directory does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not (Test-Path -Path $_ -PathType Container) ){
                throw "The RulesPath argument must be a directory. Files are not allowed."
            }
            return $true
        })]
        [System.IO.DirectoryInfo]$RulesPath,

        # location where the authorization server will sends the user once is authenticated.
        [Parameter(Mandatory = $false)]
        [uri]$RedirectUri,

        # Indicates whether AcquireToken should automatically prompt only if necessary or whether it should prompt regardless of whether there is a cached token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [ValidateSet("SelectAccount", "NoPrompt", "Never", "ForceLogin")]
        [String]$PromptBehavior,

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Force Authentication Context. Only valid for user&password auth method")]
        [Switch]$ForceAuth,

        [Parameter(Mandatory=$false, HelpMessage="Force silent authentication")]
        [Switch]$Silent,

        [Parameter(Mandatory=$false, ParameterSetName = 'Implicit', HelpMessage="Device code authentication")]
        [Switch]$DeviceCode,

        [Parameter(Mandatory=$false, HelpMessage="Force to load MSAL Desktop PowerShell Core on Windows")]
        [Switch]$ForceMSALDesktop,

        [Parameter(Mandatory=$false, HelpMessage="List available collectors")]
        [Switch]$ListCollector
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
            $analysis_attr_name.Mandatory = $false
            $attributeCollection.Add($analysis_attr_name)

            # set the ValidateSet attribute
            $token_attr_name = New-Object System.Management.Automation.ValidateSetAttribute($instance_class.Item($Instance))
            $attributeCollection.Add($token_attr_name)

            # create the dynamic -Collect parameter
            $analysis_pname = 'Collect'
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
        $Host.UI.RawUI.WindowTitle = "Monkey365 Cloud Security Scanner"
        #Start Time
        $starttimer = Get-Date
        #####Get Default parameters ########
        $MyParams = $PSBoundParameters
        #Create O365 object
        New-O365Object
        #Set timer
        $O365Object.startDate = $starttimer
        Update-PsObject
        #Initialize Logger
        Initialize-MonkeyLogger
        #Check if import job
        If($PSBoundParameters.ContainsKey('ImportJob') -and $PSBoundParameters.ImportJob){
            Import-MonkeyJob
            return
        }
        #Check if list collectors
        If($PSBoundParameters.ContainsKey('ListCollector') -and $PSBoundParameters['ListCollector'].IsPresent){
            #Get command Metadata
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-MonkeyCollector")
            $newPsboundParams = [ordered]@{}
            if($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                foreach($p in $param.GetEnumerator()){
                    if($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
                #Add verbose, debug
                $newPsboundParams.Add('Verbose',$O365Object.verbose)
                $newPsboundParams.Add('Debug',$O365Object.debug)
                $newPsboundParams.Add('InformationAction',$O365Object.InformationAction)
                #Add services if exists
                If($null -ne $O365Object.initParams.Collect -and $O365Object.initParams.Collect.Count -gt 0){
                    #Remove all option
                    $collect = $O365Object.initParams.Collect.Where({$_.ToLower() -ne 'all'})
                    [void]$newPsboundParams.Add('Service',$collect);
                }
                #Add pretty print
                [void]$newPsboundParams.Add('Pretty',$true);
                #Add Provider
                If($PSBoundParameters.ContainsKey('Instance') -and $PSBoundParameters['Instance']){
                    [void]$newPsboundParams.Add('Provider',$PSBoundParameters['Instance']);
                }
                #Execute command
                Get-MonkeyCollector @newPsboundParams
            }
            return
        }
        #Check if list collectors
        If($PSBoundParameters.ContainsKey('ListRule') -and $PSBoundParameters['ListRule'].IsPresent){
            #Get command Metadata
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-Rule")
            $newPsboundParams = [ordered]@{}
            if($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                foreach($p in $param.GetEnumerator()){
                    if($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
                #Add verbose, debug
                $newPsboundParams.Add('Verbose',$O365Object.verbose)
                $newPsboundParams.Add('Debug',$O365Object.debug)
                $newPsboundParams.Add('InformationAction',$O365Object.InformationAction)
                #Add pretty print
                [void]$newPsboundParams.Add('Pretty',$true);
                #Add RulesPath
                If($newPsboundParams.Contains('RulesPath')){
                    $newPsboundParams.RulesPath = $O365Object.rulesPath;
                }
                Else{
                    [void]$newPsboundParams.Add('RulesPath',$O365Object.rulesPath);
                }
                #Remove RuleSet if null
                If($newPsboundParams.Contains('RuleSet') -and $null -eq $newPsboundParams['RuleSet']){
                    [void]$newPsboundParams.Remove('RuleSet');
                }
                #Remove instance if EntraID is selected
                If($newPsboundParams.Contains('Instance') -and $newPsboundParams['Instance'] -eq 'EntraID'){
                    [void]$newPsboundParams.Remove('Instance');
                }
                #Remove Instance if null
                If($newPsboundParams.Contains('Instance') -and $null -eq $newPsboundParams['Instance']){
                    [void]$newPsboundParams.Remove('Instance');
                }
                #Execute command
                Get-Rule @newPsboundParams
            }
            return
        }
        #Check for mandatory params
        Test-MandatoryParameter
        #Import MSAL module
        $msg = @{
            MessageData = "Importing MSAL authentication library";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('Monkey365LoadMSAL');
        }
        Write-Information @msg
        $MSAL = ("{0}{1}core/modules/monkeymsal" -f $O365Object.Localpath,[System.IO.Path]::DirectorySeparatorChar)
        Import-Module $MSAL -Scope Global -Force -ArgumentList $O365Object.forceMSALDesktop
        ################### End Validate parameters #####################
        #Initialize authentication parameters
        Initialize-AuthenticationParam
        #Connect
        Connect-MonkeyCloud
        #Start Watcher
        If($null -ne (Get-Command -Name "Watch-AccessToken" -ErrorAction ignore)){
            Watch-AccessToken
        }
    }
    Process{
        if(($O365Object.onlineServices.GetEnumerator() | Where-Object {$_.Value -eq $true})){
            switch ($O365Object.Instance.ToLower()){
                'azure'{
                    Invoke-AzureScanner
                }
                'microsoft365'{
                    Invoke-M365Scanner
                }
                'entraid'{
                    Invoke-EntraIDScanner
                }
                default{
                    throw ("{0}" -f "Unable to recognize {0} environment",$O365Object.Instance.ToLower())
                }
            }
        }
    }
    End{
        try{
            #Stop timer
            $stoptimer = Get-Date
            $elapsedTime =  [math]::round(($stoptimer - $starttimer).TotalMinutes , 2)
            $msg = @{
                MessageData = ($message.TimeElapsedScript -f $elapsedTime);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $script:InformationAction;
                Tags = @('Monkey365FinishedJobs');
            }
            Write-Information @msg
            #Stop Watcher
            if($null -ne (Get-Command -Name "Watch-AccessToken" -ErrorAction ignore)){
                Watch-AccessToken -Stop
            }
            #Stop loggers
            Stop-Logger
        }
        catch{
            Write-Error $_
        }
        Finally{
            #Remove Report variable
            if($null -ne (Get-Variable -Name Report -Scope Script -ErrorAction Ignore)){
                Remove-Variable -Name Report -Scope Script -Force
            }
            #Remove Report variable
            if($null -ne (Get-Variable -Name returnData -Scope Script -ErrorAction Ignore)){
                Remove-Variable -Name returnData -Scope Script -Force
            }
            #collect garbage
            [System.GC]::GetTotalMemory($true) | out-null
        }
    }
}

