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

    if($null -ne $O365Object.subscriptions){
        #Set count to Zero
        $count = 0;
        foreach($subscription in $O365Object.subscriptions){
            $msg = @{
                MessageData = ($message.SubscriptionWorkingMessage -f $subscription.displayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AzureSubscriptionScanner');
            }
            Write-Information @msg
            #set script vars
            Set-Variable subscription -Value $subscription -Scope Script -Force
            Set-Variable tenant -Value $subscription.Tenant -Scope Script -Force
            Set-Variable tenantID -Value $subscription.TenantID -Scope Script -Force
            #Add current subscription to O365Object
            $O365Object.current_subscription = $subscription
            #Update authentication objects
            Update-MonkeyAuthObject -authObjects $Script:o365_connections -Force
            $O365Object.userPermissions = Get-MonkeyRBACMember -CurrentUser
            #Get ExecutionInfo
            $O365Object.executionInfo = Get-ExecutionInfo
            #Get resources and resource groups
            if($null -ne $Script:o365_connections.ResourceManager -AND $null -ne $Script:subscription.SubscriptionId){
                $msg = @{
                    MessageData = ($message.SubscriptionResourcesMessage -f $subscription.displayName);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
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
                $all_rg = Get-MonkeyAzResourceGroup -resourceGroupNames $rg_names
                if($all_rg){
                    $O365Object.ResourceGroups = $all_rg
                }
                #Get all resources within subscription
                $all_resources = Get-MonkeyAzResource -resourceGroupNames $rg_names
                if($all_resources){
                    $O365Object.all_resources = $all_resources
                }
            }
            #Check if should remove AAD plugins
            if($count -gt 0){
                #Set null new_aad_object
                $new_aad_object = $null
                if($returnData -is [System.Collections.Hashtable]){
                    $aad_objects = $returnData.GetEnumerator() | Where-Object {$_.Key -like 'aad*'}
                }
                elseif($returnData -is [System.Management.Automation.PSCustomObject]){
                    $aad_objects = $returnData.psobject.properties | Where-Object {$_.name -like "aad*"} | Select-Object Name, Value
                }
                else{
                    $msg = @{
                        MessageData = ("Unable to recognize Object");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $InformationAction;
                        Tags = @('ReturnObjectErrorType');
                    }
                    Write-Warning @msg
                    $aad_objects = $null
                }
                if($aad_objects){
                    $new_object = Copy-psObject -object $aad_objects
                    if($new_object){
                        $new_aad_object = ConvertTo-MonkeyObject -objects $new_object
                    }
                    else{
                        $new_aad_object = $null
                    }
                }
                if($null -ne $new_aad_object){
                    Set-Variable ReturnData -Value $new_aad_object -Scope Script -Force
                    #remove Azure AD plugins
                    $Plugins = $O365Object.Plugins | Where-Object {$_.FullName -notlike "*aad/graph*" -or $_.FullName -notlike "*aad/portal*"}
                    if($Plugins){
                        $O365Object.Plugins = $Plugins
                    }
                }
                else{
                    Set-Variable returnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
                }
            }
            #Set vars
            $vars = @{
                'O365Object' = $O365Object;
                'WriteLog' = $WriteLog;
                'Verbosity' = $Verbosity;
                'InformationAction' = $InformationAction;
                'returnData' = $Script:returnData;
            }
            <#
            #Convert plugins to AST (Abstract Syntax Tree) objects
            $localparams = @{
                objects = $O365Object.Plugins;
                recursive = $false;
            }
            $ast_plugins = Get-AstFunction @localparams
            if($null -ne $ast_plugins){
                #Create runspacePool
                $localparams = @{
                    ImportVariables = $vars;
                    ImportModules = $O365Object.runspaces_modules;
                    ImportCommands = $O365Object.libutils;
                    ImportCommandsAst = $ast_plugins;
                    ApartmentState = "STA";
                    Throttle = $O365Object.Threads;
                }
                #Get runspace pool
                $runspacepool = New-RunspacePool @localparams
                if($null -ne $runspacepool -and $runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                    #Save runspacePool
                    $O365Object.monkey_runspacePool = $runspacepool;
                }
                else{
                    $msg = @{
                        MessageData = ("Unable to create runspacePool");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $InformationAction;
                        Tags = @('RunspacePoolError');
                    }
                    Write-Warning @msg
                    return
                }
            }
            #Invoke new scan
            $param = @{
                plugins = $ast_plugins;
            }
            New-MonkeyRunspaceJobs @param
            #>

            #Invoke new scan
            $params = @{
                ImportPlugins = $O365Object.Plugins;
                ImportVariables = $vars;
                ImportCommands = $O365Object.libutils;
                ImportModules = $O365Object.runspaces_modules;
                Throttle = $O365Object.threads;
                StartUpScripts = $O365Object.runspace_init;
                ThrowOnRunspaceOpenError = $true;
                BatchSleep = $O365Object.BatchSleep;
                BatchSize = $O365Object.BatchSize;
                Debug = $O365Object.VerboseOptions.Debug;
                Verbose = $O365Object.VerboseOptions.Verbose;
            }
            Invoke-MonkeyRunspace @params
            #Get Monkey Object with all data to export
            $MonkeyExportObject = New-O365ExportObject
            #Prepare Output
            Out-MonkeyData -MonkeyExportObject $MonkeyExportObject
            #Increment count
            $count+= 1
        }
    }
}
