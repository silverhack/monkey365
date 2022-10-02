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
        $paths = @('core/api/azure','core/api/o365','core/utils','core/init')
        foreach($_path in $paths){
            $api_path = ("{0}/{1}" -f $ScriptPath,$_path)
            $p = @{
                Path = $api_path;
                Recurse = $true;
                file= $true;
                Include = "*.ps1";
                ErrorAction = "Ignore";
            }
            $api_fnc += Get-ChildItem @p
        }
        #Add modules
        $internal_modules = @(
            'core/modules/monkeylogger',
            'core/modules/monkeywebrequest',
            'core/modules/monkeyast',
            'core/modules/monkeyjob',
            'core/modules/monkeyutils',
            'core/modules/monkeyexcel'
        )
        #msal modules
        $msal_modules = @(
            'core/modules/monkeycloudutils',
            'core/modules/monkeymsal'
            'core/modules/monkeymsalauthassistant'
        )
        #adal modules
        $adal_modules = @(
            'core/modules/monkeycloudutils',
            'core/modules/monkeyadal',
            'core/modules/monkeyadalauthassistant'
        )
        #watcher modules
        $watcher_module = @(
            'core/watcher'
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
            ('{0}/core/modules/monkeywebrequest' -f $ScriptPath),
            ('{0}/core/modules/monkeylogger' -f $ScriptPath),
            ('{0}/core/modules/monkeyast' -f $ScriptPath),
            ('{0}/core/modules/monkeyjob' -f $ScriptPath),
            ('{0}/core/api/o365/SharePointOnline/helpers/common/enum.ps1' -f $ScriptPath)
        )
        #JSON config
        $json_path = ("{0}/config/monkey_365.config" -f $ScriptPath)
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
        #Create and return a new PsObject
        $tmp_object = [ordered]@{
            Environment = $null;
            internal_modules = $internal_modules;
            msal_modules = $msal_modules;
            adal_modules = $adal_modules;
            watcher = $watcher_module;
            runspaces_modules = $runspaces_modules;
            runspace_init = $runspace_init;
            exo_runspace_init = $exo_runspace_init;
            libutils = $api_fnc;
            OnlineServices = $null;
            Localpath =  $ScriptPath;
            auth_tokens = $null;
            userPrincipalName = $null;
            userId = $null;
            orgRegions = $null;
            Tenant = $null;
            Plugins = $null;
            ATPEnabled = $null;
            Licensing = $null;
            LogPath = $null;
            exo_session_start_time = $null;
            compliance_session_start_time = $null;
            exo_msal_application = $null;
            sps_msal_application = $null;
            authContext = $null;
            msalapplication = $null;
            adal_credentials = $null;
            adal_application = $null;
            application_args = $null;
            msal_application_args = $null;
            msal_client_app_args = $null;
            o365_sessions = $null;
            isConfidentialApp = $null;
            isUsingAdalLib = $null;
            InformationAction= $null;
            VerboseOptions = $null;
            AuthType = $null;
            WriteLog = $null;
            userAgent = $null;
            subscriptions = $null;
            current_subscription = $null;
            userPermissions = $null;
            all_resources = $null;
            ResourceGroups = $null;
            internal_config = $internal_config_json;
            dlp = $internal_dlp_json;
            AuthResponses = $null;
            executionInfo = $null;
            startDate = $null;
            exo_runspacePool = $null;
            monkey_runspacePool = $null;
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
            nestedRunspaceMaxThreads = $null;
        }
        #Check if Myparams is present
        if($null -ne (Get-Variable -Name MyParams -ErrorAction Ignore)){
            $tmp_object.outDir = $MyParams.outDir;
            $tmp_object.threads = $MyParams.Threads;
            $tmp_object.SaveProject = $MyParams.SaveProject;
            $tmp_object.Instance = $MyParams.Instance;
            $tmp_object.IncludeAAD = $MyParams.IncludeAzureActiveDirectory;
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
        $MyO365Object = New-Object -TypeName PSCustomObject -Property $tmp_object
        #update User Agent
        $MyO365Object.userAgent = Get-MonkeyUserAgent
        #Return object
        return $MyO365Object
    }
    catch{
        throw ("{0}: {1}" -f "Unable to create new object",$_.Exception.Message)
    }
}
