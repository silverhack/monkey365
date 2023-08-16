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
    try{
        #api Path
        $api_fnc= @()
        $paths = @(
            'core/api/azure',
            'core/api/azuread',
            'core/api/m365',
            'core/utils',
            'core/init',
            'core/tenant',
            'core/subscription',
            'core/watcher'
        )
        foreach($_path in $paths){
            $api_path = ("{0}/{1}" -f $ScriptPath,$_path)
            if ([System.IO.Directory]::Exists($api_path)){
                $api_fnc += [System.IO.Directory]::EnumerateFiles($api_path,"*.ps1",[System.IO.SearchOption]::AllDirectories)
            }
        }
        #Add modules
        $internal_modules = @(
            'core/modules/monkeylogger',
            'core/modules/monkeyhttpwebrequest',
            'core/modules/monkeyast',
            'core/modules/monkeyjob',
            'core/modules/monkeyutils',
            'core/modules/monkeyexcel'
        )
        #msal modules
        $msal_modules = @(
            'core/modules/monkeycloudutils',
            'core/modules/monkeymsal',
            'core/modules/monkeymsalauthassistant'
        )
        #watcher modules
        $watcher_module = @(
            'core/watcher',
            'core/init',
            'core/modules/monkeymsalauthassistant',
            'core/modules/monkeycloudutils'
        )
        #Runspace init
        $runspace_init = @(
            ('{0}/core/runspace_init/Initialize-MonkeyRunspace.ps1' -f $ScriptPath)
        )
        #EXO Runspace init
        $exo_runspace_init = @(
            ('{0}/core/runspace_init/Initialize-MonkeyExoRunspace.ps1' -f $ScriptPath)
        )
        #runspaces modules
        $runspaces_modules = @(
            ('{0}/core/modules/monkeyhttpwebrequest' -f $ScriptPath),
            ('{0}/core/modules/monkeylogger' -f $ScriptPath),
            ('{0}/core/modules/monkeyast' -f $ScriptPath),
            ('{0}/core/modules/monkeyjob' -f $ScriptPath),
            ('{0}/core/modules/monkeyutils' -f $ScriptPath),
            ('{0}/core/modules/monkeycloudutils' -f $ScriptPath),
            ('{0}/core/api/m365/SharePointOnline/utils/enum.ps1' -f $ScriptPath)
        )
        #JSON config
        $json_path = ("{0}/core/utils/whatIf/whatIf.json" -f $ScriptPath)
        if (!(Test-Path -Path $json_path)){
            throw ("{0} whatif config does not exists" -f $json_path)
        }
        $whatif_config_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
        #JSON config
        $json_path = ("{0}/config/monkey365.config" -f $ScriptPath)
        if (!(Test-Path -Path $json_path)){
            throw ("{0} config does not exists" -f $json_path)
        }
        $internal_config_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
        #DLP config
        $json_path = ("{0}/core/utils/dlp/monkeydlp.json" -f $ScriptPath)
        if (!(Test-Path -Path $json_path)){
            throw ("{0} dlp file does not exists" -f $json_path)
        }
        $internal_dlp_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
        #Get User Properties
        $json_path = ("{0}/core/utils/properties/monkeyuserprop.json" -f $ScriptPath)
        if (!(Test-Path -Path $json_path)){
            throw ("{0} user properties file does not exists" -f $json_path)
        }
        $user_prop_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
        #Get diag settings unsupported resources
        $json_path = ("{0}/core/utils/diagnosticSettings/unsupportedResources.json" -f $ScriptPath)
        if (!(Test-Path -Path $json_path)){
            throw ("{0} diagnostic settings file does not exists" -f $json_path)
        }
        $diag_settings_json = (Get-Content $json_path -Raw) | ConvertFrom-Json
        #Create and return a new PsObject
        $tmp_object = [ordered]@{
            Environment = $null;
            internal_modules = $internal_modules;
            msal_modules = $msal_modules;
            watcher = $watcher_module;
            runspaces_modules = $runspaces_modules;
            runspace_init = $runspace_init;
            exo_runspace_init = $exo_runspace_init;
            runspace_vars = $null;
            libutils = $api_fnc;
            onlineServices = $null;
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
            });
            userPrincipalName = $null;
            userId = $null;
            orgRegions = $null;
            Tenant = $null;
            tenantOrigin = $null;
            Plugins = $null;
            ATPEnabled = $null;
            AADLicense = $null;
            Licensing = $null;
            LogPath = $null;
            msal_public_applications = $null
            msal_confidential_applications = $null
            exo_msal_application = $null;
            sps_msal_application = $null;
            authContext = $null;
            msalapplication = $null;
            application_args = $null;
            msal_application_args = $null;
            msal_client_app_args = $null;
            authentication_args = $null;
            o365_sessions = [hashtable]::Synchronized(@{
                ExchangeOnline = $null;
                ComplianceCenter = $null;
                Lync = $null;
                AADRM = $null;
            });
            isConfidentialApp = $null;
            isSharePointAdministrator = $null;
            spoWebs = $null;
            InformationAction= $null;
            VerboseOptions = $null;
            AuthType = $null;
            WriteLog = $null;
            userAgent = $null;
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
            whatIfConfig = $whatif_config_json;
            dlp = $internal_dlp_json;
            executionInfo = $null;
            startDate = $null;
            exo_runspacePool = $null;
            monkey_runspacePool = $null;
            monkey_m365RunspacePool = $null;
            threads= $null;
            SaveProject= $null;
            Instance= $null;
            IncludeAAD= $null;
            verbose= $null;
            debug= $null;
            initParams= $null;
            clientApplicationId= $null;
            TenantId = $null;
            exportTo= $null;
            LocalizedDataParams = $null;
            BatchSleep = $internal_config_json.performance.BatchSleep;
            BatchSize = $internal_config_json.performance.BatchSize;
            MaxQueue = $internal_config_json.performance.nestedRunspaces.MaxQueue;
            nestedRunspaces = @{
                BatchSleep = ($internal_config_json.performance.BatchSleep * 2);
                BatchSize = ($internal_config_json.performance.BatchSize * 2);
                MaxQueue = $internal_config_json.performance.nestedRunspaces.MaxQueue;
            }
            nestedRunspaceMaxThreads = $null;
            PowerBIBackendUri = $null;
            SecCompBackendUri = $null;
            Timer = $null;
            me = $null;
            HttpClient = $null;
            SystemInfo = $null;
            diag_settings_unsupported_resources = $diag_settings_json;
        }
        #Check if Myparams is present
        if($null -ne (Get-Variable -Name MyParams -ErrorAction Ignore)){
            $tmp_object.OutDir = $MyParams.OutDir;
            $tmp_object.threads = $MyParams.Threads;
            $tmp_object.SaveProject = $MyParams.SaveProject;
            $tmp_object.Instance = $MyParams.Instance;
            $tmp_object.IncludeAAD = $MyParams.IncludeAzureAD;
            $tmp_object.verbose = $MyParams.verbose;
            $tmp_object.debug = $MyParams.debug;
            $tmp_object.initParams = $MyParams;
            $tmp_object.clientApplicationId = $MyParams.ClientId;
            $tmp_object.WriteLog = $MyParams.WriteLog;
            $tmp_object.TenantId = $MyParams.TenantId;
            $tmp_object.exportTo = $MyParams.exportTo;
            $tmp_object.excludePlugins = $MyParams.ExcludePlugin;
            $tmp_object.excludedResources = $MyParams.ExcludedResources;
            #Calculate threads for nested runspaces
            [int]$value = ($MyParams.Threads / 2)
            if($value -eq 0){$value = 1}
            #Add to object
            $tmp_object.nestedRunspaceMaxThreads = $value;
        }
        #Get SystemInfo
        if($null -ne (Get-Command -Name "Get-MonkeySystemInfo" -ErrorAction Ignore)){
            $tmp_object.SystemInfo = Get-MonkeySystemInfo
            #Get OS version
            if($null -ne (Get-Command -Name "Get-OSVersion" -ErrorAction Ignore) -and $null -ne $tmp_object.SystemInfo){
                $tmp_object.SystemInfo.OSVersion = Get-OSVersion
            }
        }
        #Check if verbose options are present
        if($null -ne (Get-Variable -Name VerboseOptions -ErrorAction Ignore)){
            $tmp_object.VerboseOptions = $VerboseOptions;
        }
        #Check if localized strings are present
        if($null -ne (Get-Variable -Name LocalizedDataParams -ErrorAction Ignore)){
            $tmp_object.LocalizedDataParams = $LocalizedDataParams;
        }
        #Check if InformationAction is present
        if($null -ne (Get-Variable -Name InformationAction -ErrorAction Ignore)){
            New-Variable -Name InformationAction -Scope Script -Value ($InformationAction) -Force
            $tmp_object.InformationAction = $InformationAction;
        }
        #Check if OnlineServices is present
        if($null -ne (Get-Variable -Name OnlineServices -ErrorAction Ignore)){
            $tmp_object.onlineServices = $OnlineServices;
        }
        $MyO365Object = New-Object -TypeName PSCustomObject -Property $tmp_object
        #update User Agent
        $MyO365Object.userAgent = Get-MonkeyUserAgent
        #Add timer
        $Timer = [Timers.Timer]::new()
        $Timer.AutoReset = $true;
        $TimeSpan = New-TimeSpan -Minutes 5
        $Timer.Interval = $TimeSpan.TotalMilliseconds
        $Timer.Enabled = $True
        $MyO365Object.Timer = $Timer
        #Create Object
        New-Variable -Name O365Object -Value $MyO365Object -Scope Script -Force
    }
    catch{
        throw ("{0}: {1}" -f "Unable to create new object",$_.Exception.Message)
    }
}
