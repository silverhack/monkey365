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
# See the License for the specIfic language governing permissions and
# limitations under the License.


Function New-O365Object{
    <#
        .SYNOPSIS
		Function to create new O365Object

        .DESCRIPTION
		Function to create new O365Object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-O365Object
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    Begin{
        try{
            #Check for MyParams var
            If($null -eq (Get-Variable -Name MyParams -ErrorAction Ignore)){
                $MyParams = @{}
                return
            }
            #Set vars
            $OnlineServices = @{}
            $VerboseOptions = @{}
            $SystemInfo = $UserAgent = $nestedMaxThreads = $internal_config_json = $null
            #Init params
            $init_params = @(
                'AuditorName','Threads',
                'PromptBehavior','Environment',
                'Instance', 'Ruleset','RulesPath','ExportTo',
                'Collect','WriteLog','TenantId','ClientId',
                'IncludeEntraID','ImportJob',
                'SaveProject','ResolveTenantDomainName',
                'ResolveTenantUserName','ExcludeCollector',
                'ExcludedResources','ForceMSALDesktop',
                'Compress'
            )
            #Get SystemInfo
            If($null -ne (Get-Command -Name "Get-MonkeySystemInfo" -ErrorAction Ignore)){
                $SystemInfo = Get-MonkeySystemInfo
                #Get OS version
                If($null -ne (Get-Command -Name "Get-OSVersion" -ErrorAction Ignore) -and $null -ne $SystemInfo){
                    $SystemInfo.OSVersion = Get-OSVersion
                }
                If($null -ne $SystemInfo -and ($MyParams.ContainsKey('ForceMSALDesktop') -and $MyParams['ForceMSALDesktop'])){
                    $SystemInfo.MsalType = 'Desktop'
                }
            }
            #Get a new User-Agent
            $UserAgent = Get-MonkeyUserAgent
            #Set OnlineServices
            If($null -ne (Get-Variable -Name m365_plugins -ErrorAction Ignore)){
                #Add Azure and EntraID
                [ref]$null = $OnlineServices.Add('Azure',$false)
                [ref]$null = $OnlineServices.Add('EntraID',$false)
                #Iterate over all Microsoft 365 services
                ForEach($service in $m365_plugins.GetEnumerator()){
                    [ref]$null = $OnlineServices.Add($service,$false)
                }
            }
            ################### VERBOSE OPTIONS #######################
            #Check verbose options
            If($MyParams.ContainsKey('Verbose') -and $MyParams.Verbose -eq $true){
                [void]$VerboseOptions.Add('Verbose',$true);
                [void]$VerboseOptions.Add('VerbosePreference','Continue');
            }
            Else{
                [void]$VerboseOptions.Add('Verbose',$false);
                [void]$VerboseOptions.Add('VerbosePreference','SilentlyContinue');
            }
            #Check Debug options
            If($MyParams.ContainsKey('Debug') -and $MyParams.Debug -eq $true){
                [void]$VerboseOptions.Add('DebugPreference','Continue');
                [void]$VerboseOptions.Add("Debug",$true)
            }
            Else{
                [void]$VerboseOptions.Add("Debug",$false);
                [void]$VerboseOptions.Add('DebugPreference','SilentlyContinue')
            }
            ################### LOG, CONSOLE OPTIONS #######################
            If($MyParams.ContainsKey('InformationAction')){
                Set-Variable InformationAction -Value $MyParams.InformationAction -Scope Script -Force
            }
            Else{
                Set-Variable InformationAction -Value "SilentlyContinue" -Scope Script -Force
            }
            ################## Set Initial params #########################
            ForEach ($p in $init_params){
                If ($false -eq $MyParams.ContainsKey($p)){
                    [void]$MyParams.Add($p,$null)
                }
            }
            #Set Compress option
            If($null -eq $MyParams.Compress){
                $MyParams.Compress = $false
            }
            #Set Output Dir
            If($false -eq $MyParams.ContainsKey('OutDir')){
                $MyParams.OutDir = ("{0}/monkey-reports" -f $ScriptPath)
            }
            #Set Environment
            If($null -eq $MyParams.Environment){
                $MyParams.Environment = $Environment
            }
            <#
            #Set Prompt
            If($null -eq $MyParams.PromptBehavior){
                $MyParams.PromptBehavior = 'Auto'
            }
            #>
            #Add threads to params If not exists
            If($null -eq $MyParams.Threads){
                $MyParams.Threads = 2;
            }
            #Add auditorName If not exists
            If($null -eq $MyParams.auditorName){
                $MyParams.AuditorName = $env:USERNAME
            }
            #TODO Set instance
            If($null -eq $MyParams.Instance -and $null -ne $MyParams.IncludeEntraID){
                $MyParams.Instance = 'EntraID';
            }
            #Set Verbose and Debug options
            If($false -eq $MyParams.ContainsKey('Verbose')){
                $MyParams.Verbose = $false
            }
            If($false -eq $MyParams.ContainsKey('Debug')){
                $MyParams.Debug = $false
            }
            #Set informationAction
            If($false -eq $MyParams.ContainsKey('InformationAction')){
                $MyParams.InformationAction = 'SilentlyContinue'
            }
            #Override params with environment vars If any
            #Check If username and password
            If ((Test-Path env:MONKEY_ENV_MONKEY_USER) -and (Test-Path env:MONKEY_ENV_MONKEY_PASSWORD)){
                try{
                    [securestring]$cred = ConvertTo-SecureString $env:MONKEY_ENV_MONKEY_PASSWORD
                    [pscredential]$InputObject = New-Object System.Management.Automation.PSCredential ($env:MONKEY_ENV_MONKEY_USER, $cred)
                    $MyParams.UserCredentials = $InputObject
                }
                catch{
                    Write-Error $_
                }
            }
            #Check If TenantID
            If (Test-Path env:MONKEY_ENV_TENANT_ID){
                $MyParams.TenantID = $env:MONKEY_ENV_TENANT_ID
            }
            #Check If AuthMode
            If (Test-Path env:MONKEY_ENV_AUTH_MODE){
                $MyParams.AuthMode = $env:MONKEY_ENV_AUTH_MODE
            }
            #Check If subscriptions
            If (Test-Path env:MONKEY_ENV_SUBSCRIPTIONS){
                $MyParams.Subscriptions = $env:MONKEY_ENV_SUBSCRIPTIONS
            }
            #Check If collect
            If (Test-Path env:MONKEY_ENV_COLLECT){
                $collect = @()
                ForEach($element in $env:MONKEY_ENV_COLLECT.Split(',')){
                    $collect+=$element
                }
                If('all' -in $collect){
                    [void]$collect.Clear();
                    $collect+='all'
                }
                If($collect.Count -gt 0){
                    #Remove duplicate before adding data to analysis var
                    $MyParams.Collect = $collect | Sort-Object -Property @{Expression={$_.Trim()}} -Unique
                }
            }
            #Check If exportTo
            If (Test-Path env:MONKEY_ENV_EXPORT_TO){
                $exportTo = @()
                ForEach($element in $env:MONKEY_ENV_EXPORT_TO.Split(',')){
                    $exportTo+=$element
                }
                If($exportTo.Count -gt 0){
                    #Remove duplicate before adding data to exportTo var
                    $MyParams.ExportTo = $exportTo | Sort-Object -Property @{Expression={$_.Trim()}} -Unique
                }
            }
            #Check If writelog
            If (Test-Path env:MONKEY_ENV_WRITELOG){
                try{
                    $MyParams.WriteLog = [System.Convert]::ToBoolean($env:MONKEY_ENV_WRITELOG)
                }
                catch{
                    $MyParams.WriteLog = $false
                }
            }
            #Check If Verbose
            If (Test-Path env:MONKEY_ENV_VERBOSE){
                try{
                    $MyParams.Verbose = [System.Convert]::ToBoolean($env:MONKEY_ENV_VERBOSE)
                }
                catch{
                    $MyParams.Verbose = $false
                }
            }
            #Check If Debug
            If (Test-Path env:MONKEY_ENV_DEBUG){
                try{
                    $MyParams.Debug = [System.Convert]::ToBoolean($env:MONKEY_ENV_DEBUG)
                }
                catch{
                    $MyParams.Debug = $false
                }
            }
            #Calculate threads for nested runspaces
            [int]$nestedMaxThreads = ($MyParams.Threads / 2)
            If($nestedMaxThreads -eq 0){$nestedMaxThreads = 1}
        }
        Catch{
            throw ("[ParameterError] {0}: {1}" -f "Unable to create Monkey365 object",$_.Exception.Message)
        }
    }
    Process{
        #Get config files
        #JSON config
        try{
            $json_path = ("{0}/config/monkey365.config" -f $ScriptPath)
            If (!(Test-Path -Path $json_path)){
                throw ("{0} config does not exists" -f $json_path)
            }
            $internal_config_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
            #DLP config
            $json_path = ("{0}/core/utils/dlp/monkeydlp.json" -f $ScriptPath)
            If (!(Test-Path -Path $json_path)){
                throw ("{0} dlp file does not exists" -f $json_path)
            }
            $internal_dlp_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
            #Get User Properties
            $json_path = ("{0}/core/utils/properties/monkeyuserprop.json" -f $ScriptPath)
            If (!(Test-Path -Path $json_path)){
                throw ("{0} user properties file does not exists" -f $json_path)
            }
            $user_prop_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
            #Get diag settings unsupported resources
            $json_path = ("{0}/core/utils/diagnosticSettings/unsupportedResources.json" -f $ScriptPath)
            If (!(Test-Path -Path $json_path)){
                throw ("{0} diagnostic settings file does not exists" -f $json_path)
            }
            $diag_settings_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
            ############ Get Ruleset info ################
            $ruleSet = $rulesPath = $null;
            #Get ruleset
            If($null -ne $MyParams.ruleset){
                $ruleSet = $MyParams.ruleset
            }
            Else{
                If($null -ne $MyParams.Instance -and $MyParams.Instance.ToLower() -eq "azure"){
                    $ruleSet = $internal_config_json.ruleSettings.azureDefaultRuleset
                }
                ElseIf($null -ne $MyParams.Instance -and $MyParams.Instance.ToLower() -eq "microsoft365"){
                    $ruleSet = $internal_config_json.ruleSettings.m365DefaultRuleset
                }
                Else{
                    #Probably Azure AD
                    $ruleSet = $internal_config_json.ruleSettings.m365DefaultRuleset
                }
            }
            $isRoot = [System.IO.Path]::IsPathRooted($ruleSet)
            If(-NOT $isRoot){
                $ruleSet = ("{0}/{1}" -f $ScriptPath, $ruleSet)
            }
            If (!(Test-Path -Path $ruleSet)){
                Write-Warning ("{0} not found" -f $ruleSet)
                $ruleSet = $null;
            }
            #Get rulespath
            If($null -ne $MyParams.RulesPath){
                $rulesPath = $MyParams.RulesPath
            }
            Else{
                $rulesPath = $internal_config_json.ruleSettings.rules
            }
            $isRoot = [System.IO.Path]::IsPathRooted($rulesPath)
            If(-NOT $isRoot){
                $rulesPath = ("{0}/{1}" -f $ScriptPath, $rulesPath)
            }
            If (!(Test-Path -Path $rulesPath)){
                Write-Warning ("{0} not found" -f $rulesPath)
                $rulesPath = $null;
            }
        }
        Catch{
            throw ("[ConfigFileError] {0}: {1}" -f "Unable to create Monkey365 object",$_.Exception.Message)
        }
        #Get Path libs
        Try{
            #Runspace init
            $runspace_init = @(
                ('{0}/core/runspace_init/Initialize-MonkeyRunspace.ps1' -f $ScriptPath)
            )
            #runspaces modules
            $runspaces_modules = @(
                ('{0}/core/modules/monkeylogger' -f $ScriptPath),
                ('{0}/core/modules/monkeyhttpwebrequest' -f $ScriptPath),
                ('{0}/core/modules/monkeyjob' -f $ScriptPath),
                ('{0}/core/modules/monkeyutils' -f $ScriptPath),
                ('{0}/core/modules/monkeycloudutils' -f $ScriptPath),
                ('{0}/core/api/m365/sharepointonline/utils/enum.ps1' -f $ScriptPath)
                ('{0}/core/tasks/Initialize-MonkeyScan.ps1' -f $ScriptPath)
            )
        }
        Catch{
            throw ("[MonkeyLibError] {0}: {1}" -f "Unable to create Monkey365 object",$_.Exception.Message)
        }
    }
    End{
        Try{
            #Create and return a new PsObject
            $tmp_object = [ordered]@{
                Environment = Get-MonkeyEnvironment -Environment $MyParams.Environment;
                cloudEnvironment = $MyParams.Environment;
                runspaces_modules = $runspaces_modules;
                runspace_init = $runspace_init;
                runspace_vars = $null;
                onlineServices = $OnlineServices;
                Localpath =  $ScriptPath;
                InitialPath = (Get-Location -PSProvider FileSystem).ProviderPath;
                auth_tokens = [hashtable]::Synchronized(@{
                    Graph = $null;
                    Intune = $null;
                    ExchangeOnline = $null;
                    ResourceManager = $null;
                    ServiceManagement = $null;
                    SecurityPortal = $null;
                    AzureVault = $null;
                    LogAnalytics = $null;
                    AzureStorage = $null;
                    ComplianceCenter = $null;
                    AzurePortal = $null;
                    Yammer = $null;
                    Forms = $null;
                    Lync= $null;
                    SharePointAdminOnline = $null;
                    SharePointOnline = $null;
                    OneDrive = $null;
                    AADRM = $null;
                    MSGraph = $null;
                    Teams = $null;
                    PowerBI = $null;
                    M365Admin = $null;
                    MSPIM = $null;
                    Fabric = $null;
                });
                userPrincipalName = $null;
                userId = $null;
                orgRegions = $null;
                Tenant = [PsCustomObject]@{
                    tenantName = $null;
                    tenantId = $null;
                    companyInfo = $null;
                    sku = $null;
                    domains = $null;
                    myDomain = $null;
                    licensing = $null;
                };
                tenantOrigin = $null;
                Collectors = $null;
                Licensing = $null;
                LogPath = $null;
                loggers = $null;
                MonkeyLogQueue = [System.Collections.Concurrent.BlockingCollection[System.Management.Automation.InformationRecord]]::new();
                msal_public_applications = $null;
                msal_confidential_applications = $null;
                msalapplication = $null;
                application_args = $null;
                msal_application_args = $null;
                msalAuthArgs = $null;
                forceMSALDesktop = If($null -ne $MyParams.ForceMSALDesktop){$MyParams.ForceMSALDesktop}Else{$false};
                isConfidentialApp = $null;
                isSharePointAdministrator = $null;
                spoSites = $null;
                InformationAction= $InformationAction;
                VerboseOptions = $VerboseOptions;
                AuthType = $null;
                WriteLog = $MyParams.WriteLog;
                userAgent = $UserAgent;
                userProperties = $user_prop_json;
                subscriptions = $null;
                current_subscription = $null;
                aadPermissions = $null;
                azPermissions = $null;
                canRequestMFAForUsers = $null;
                canRequestUsersFromMsGraph = $null;
                canRequestGroupsFromMsGraph = $null;
                all_resources = $null;
                ResourceGroups = $null;
                internal_config = $internal_config_json;
                dlp = $internal_dlp_json;
                executionInfo = $null;
                startDate = $null;
                monkey_runspacePool = $null;
                threads= $MyParams.Threads;
                SaveProject= $MyParams.SaveProject;
                Instance= $MyParams.Instance;
                IncludeEntraID= $MyParams.IncludeEntraID;
                verbose= $MyParams.Verbose;
                debug= $MyParams.Debug;
                initParams= $MyParams;
                clientApplicationId= $MyParams.ClientId;
                TenantId = $MyParams.TenantId;
                isValidTenantGuid = $false;
                exportTo= $MyParams.ExportTo;
                LocalizedDataParams = $LocalizedDataParams;
                BatchSleep = $internal_config_json.performance.BatchSleep;
                BatchSize = $internal_config_json.performance.BatchSize;
                MaxQueue = $internal_config_json.performance.nestedRunspaces.MaxQueue;
                nestedRunspaces = @{
                    BatchSleep = ($internal_config_json.performance.BatchSleep * 2);
                    BatchSize = ($internal_config_json.performance.BatchSize * 2);
                    MaxQueue = $internal_config_json.performance.nestedRunspaces.MaxQueue;
                }
                nestedRunspaceMaxThreads = $nestedMaxThreads;
                PowerBIBackendUri = $null;
                SecCompBackendUri = $null;
                me = $null;
                SystemInfo = $SystemInfo;
                diag_settings_unsupported_resources = $diag_settings_json;
                OutDir = $MyParams.OutDir;
                excludeCollectors = $MyParams.ExcludeCollector;
                excludedResources = $MyParams.ExcludedResources;
                ruleset = $ruleSet;
                rulesPath = $rulesPath;
                Compress = $MyParams.Compress;
            }
            #Create new object
            $MonkeyObj = New-Object -TypeName PSCustomObject -Property $tmp_object
            #Set new internal variable
            New-Variable O365Object -Value $MonkeyObj -Scope Script -Force

        }
        Catch{
            throw ("[CustomObjectError] {0}: {1}" -f "Unable to create Monkey365 object",$_.Exception.Message)
        }
    }
}

