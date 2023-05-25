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

Function Invoke-AzureScanner{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-AzureScanner
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    #Set vars
    $azure_plugins = $null
    $aad_plugins = $null
    #Get Azure plugins
    if($null -ne $O365Object.Plugins){
        $azure_plugins = $O365Object.Plugins.Where({$_.Provider -eq "Azure"}) | Select-Object -ExpandProperty File -ErrorAction Ignore
        $aad_plugins = $O365Object.Plugins.Where({$_.Provider -eq "AzureAD"}) | Select-Object -ExpandProperty File -ErrorAction Ignore
    }
    #Set runspacePool for nested queries
    $p = @{
        Provider = "Azure";
        Throttle = $O365Object.threads;
    }
    $O365Object.monkey_runspacePool = New-MonkeyRunsPacePool @p
    #Set variable for nested runspaces
    $O365Object.runspace_vars = Get-MonkeyVar
    #Execute AAD plugins
    if($null -ne $O365Object.subscriptions -and $null -ne $aad_plugins){
        #Set synchronized hashtable
        Set-Variable aadReturnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
        $vars = @{
            O365Object = $O365Object;
            WriteLog = $O365Object.WriteLog;
            Verbosity = $O365Object.VerboseOptions;
            InformationAction = $O365Object.InformationAction;
            returnData = $Script:aadReturnData;
        }
        $p = @{
            ImportPlugins = $aad_plugins;
            ImportVariables = $vars;
            ImportCommands = $O365Object.libutils;
            ImportModules = $O365Object.runspaces_modules;
            StartUpScripts = $O365Object.runspace_init;
            ThrowOnRunspaceOpenError = $true;
            Debug = $O365Object.VerboseOptions.Debug;
            Verbose = $O365Object.VerboseOptions.Verbose;
        }
        Invoke-MonkeyRunspace @p
        #Sleep some time
        $msg = @{
            MessageData = ($Script:message.SleepMessage -f 10000);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('Monkey365SleepTime');
        }
        Write-Information @msg
        Start-Sleep -Milliseconds 10000
    }
    if($null -ne $O365Object.subscriptions -and $null -ne $azure_plugins){
        foreach($azSubscription in @($O365Object.subscriptions)){
            $msg = @{
                MessageData = ($message.SubscriptionWorkingMessage -f $azSubscription.displayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureSubscriptionScanner');
            }
            Write-Information @msg
            #Add current subscription to O365Object
            $O365Object.current_subscription = Resolve-AzureSubscription -Subscription $azSubscription
            #set legacy script vars
            Set-Variable Subscription -Value $O365Object.current_subscription -Scope Script -Force
            Set-Variable Tenant -Value $O365Object.current_subscription.Tenant -Scope Script -Force
            Set-Variable TenantID -Value $O365Object.current_subscription.TenantID -Scope Script -Force
            #Update authentication objects
            Update-MonkeyAuthObject
            $O365Object.azPermissions = Get-MonkeyAzIAMPermission -CurrentUser
            #Get ExecutionInfo
            $O365Object.executionInfo = Get-ExecutionInfo
            #Get resources and resource groups
            if($null -ne $O365Object.auth_tokens.ResourceManager -AND $null -ne $O365Object.current_subscription.SubscriptionId){
                $msg = @{
                    MessageData = ($message.SubscriptionResourcesMessage -f $O365Object.current_subscription.displayName);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureSubscriptionScanner');
                }
                Write-Information @msg
                #Get resource groups
                if($O365Object.initParams.psobject.Properties.Item('resourcegroups')){
                    $rg_names = $O365Object.initParams.resourcegroups
                }
                else{
                    $rg_names = $null
                }
                $all_rg = Get-MonkeyAzResourceGroup -ResourceGroupNames $rg_names
                if($all_rg){
                    $O365Object.ResourceGroups = $all_rg
                }
                #Get all resources within subscription
                $all_resources = Get-MonkeyAzResource -ResourceGroupNames $rg_names
                if($all_resources){
                    $O365Object.all_resources = $all_resources
                    #Check if should skip resources from being scanned
                    Skip-MonkeyAzResource
                }
            }
            #Check if plugins are present
            If(@($azure_plugins).Count -gt 0){
                #Set synchronized hashtable
                Set-Variable returnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
                $vars = @{
                    O365Object = $O365Object;
                    WriteLog = $O365Object.WriteLog;
                    Verbosity = $O365Object.VerboseOptions;
                    InformationAction = $O365Object.InformationAction;
                    returnData = $Script:returnData;
                }
                $p = @{
                    ImportPlugins = $azure_plugins;
                    ImportVariables = $vars;
                    ImportCommands = $O365Object.libutils;
                    ImportModules = $O365Object.runspaces_modules;
                    StartUpScripts = $O365Object.runspace_init;
                    ThrowOnRunspaceOpenError = $true;
                    Debug = $O365Object.VerboseOptions.Debug;
                    Verbose = $O365Object.VerboseOptions.Verbose;
                }
                Invoke-MonkeyRunspace @p
                #Check if AAD data
                if($null -ne (Get-Variable -Name aadReturnData -Scope Script -ErrorAction Ignore)){
                    $Script:returnData = Join-HashTable -HashTable $returnData -JoinHashTable $aadReturnData
                }
                #Get Monkey Object with all data to export
                $MonkeyExportObject = New-O365ExportObject
                #Prepare Output
                Out-MonkeyData -MonkeyExportObject $MonkeyExportObject
                #Reset Report var
                if($null -ne (Get-Variable -Name Report -Scope Script -ErrorAction Ignore)){
                    Remove-Variable -Name Report -Scope Script -Force
                }
                #collect garbage
                #[gc]::Collect()
                [System.GC]::GetTotalMemory($true) | out-null
                #Sleep some time
                $msg = @{
                    MessageData = ($Script:message.SleepMessage -f 10000);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('Monkey365SleepTime');
                }
                Write-Information @msg
                Start-Sleep -Milliseconds 10000
            }
        }
    }
    #Cleaning Runspace
    if($null -ne $O365Object.monkey_runspacePool -and $O365Object.monkey_runspacePool -is [System.Management.Automation.Runspaces.RunspacePool]){
        #$O365Object.monkey_runspacePool.Close()
        $O365Object.monkey_runspacePool.Dispose()
        #Perform garbage collection
        [gc]::Collect()
    }
}
