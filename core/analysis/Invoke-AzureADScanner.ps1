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

Function Invoke-AzureADScanner{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-AzureADScanner
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    #Set vars
    $aad_plugins = $null
    #Set synchronized hashtable
    Set-Variable returnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
    #Get Azure AD plugins
    if($null -ne $O365Object.Plugins){
        $aad_plugins = $O365Object.Plugins.Where({$_.Provider -eq "AzureAD"}) | Select-Object -ExpandProperty File -ErrorAction Ignore
    }
    #Set runspacePool for nested queries
    $p = @{
        Provider = "Azure";
        Throttle = $O365Object.threads;
    }
    $O365Object.monkey_runspacePool = New-MonkeyRunsPacePool @p
    if($null -ne $O365Object.TenantId -and $O365Object.Plugins){
        #Add current subscription to O365Object
        if($null -ne $O365Object.Tenant){
            $TenantObject = $O365Object.Tenant
            $displayName = $O365Object.Tenant.TenantName;
            $subscriptionId = $O365Object.Tenant.TenantId;
        }
        else{
            $msg = @{
                MessageData = ($Script:message.O365TenantInfoError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365TenantError');
            }
            Write-Warning @msg
            if($null -ne $O365Object.auth_tokens.Graph){
                $displayName = $O365Object.auth_tokens.Graph.TenantId;
                $subscriptionId = $O365Object.auth_tokens.Graph.TenantId;
            }
            else{
                $displayName = $null;
                $subscriptionId = $null;
            }
            $TenantObject = $null;
        }
        $new_subscription = [ordered]@{
            Tenant = $TenantObject;
            DisplayName = $displayName;
            subscriptionId = $subscriptionId;
        }
        $O365Object.current_subscription = $new_subscription
        #Get Execution Info
        $O365Object.executionInfo = Get-ExecutionInfo
        #Invoke new scan
        if(@($aad_plugins).Count -gt 0){
            #Set vars
            $vars = @{
                O365Object = $O365Object;
                WriteLog = $O365Object.WriteLog;
                Verbosity = $Verbosity;
                InformationAction = $O365Object.InformationAction;
                returnData = $Script:returnData;
            }
            $p = @{
                ImportPlugins = $aad_plugins;
                ImportVariables = $vars;
                ImportCommands = $O365Object.libutils;
                ImportModules = $O365Object.runspaces_modules;
                StartUpScripts = $O365Object.runspace_init;
                ThrowOnRunspaceOpenError = $true;
                Throttle = $O365Object.threads;
                BatchSleep = $O365Object.BatchSleep;
                BatchSize = $O365Object.BatchSize;
                Debug = $O365Object.VerboseOptions.Debug;
                Verbose = $O365Object.VerboseOptions.Verbose;
            }
            Invoke-MonkeyRunspace @p
            if($Script:returnData.Count -gt 0){
                $MonkeyExportObject = New-O365ExportObject
                #Prepare Output
                Out-MonkeyData -MonkeyExportObject $MonkeyExportObject
            }
            else{
                $msg = @{
                    MessageData = "There is no data to export";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureSubscriptionScanner');
                }
                Write-Warning @msg
            }
        }
    }
    #Cleaning Runspace
    if($null -ne $O365Object.monkey_runspacePool -and $O365Object.monkey_runspacePool -is [System.Management.Automation.Runspaces.RunspacePool]){
        $O365Object.monkey_runspacePool.Close()
        $O365Object.monkey_runspacePool.Dispose()
        #Perform garbage collection
        [gc]::Collect()
    }
}
