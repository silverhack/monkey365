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

Function Invoke-M365Scanner{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-O365Scanner
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    if($null -ne $O365Object.TenantId -and $O365Object.Plugins){
        #Add current subscription to O365Object
        $new_subscription = [ordered]@{
            Tenant = $O365Object.Tenant
            DisplayName = $O365Object.Tenant.TenantName
            subscriptionId = $O365Object.Tenant.TenantId
        }
        $O365Object.current_subscription = $new_subscription
        #Check for permissions
        if($O365Object.isConfidentialApp){
            $user_permissions = Get-PSGraphServicePrincipalDirectoryRole -principalId $O365Object.clientApplicationId
            if($user_permissions){
                $O365Object.userPermissions = $user_permissions
            }
        }
        else{
            $user_permissions = Get-PSGraphUserDirectoryRole -user_id $O365Object.userId
            if($user_permissions){
                $O365Object.userPermissions = $user_permissions
            }
        }
        #Get Execution Info
        $O365Object.executionInfo = Get-ExecutionInfo
        #Invoke new scan
        if($null -ne $O365Object.libutils){
            $vars = @{
                'O365Object' = $O365Object;
                'WriteLog' = $WriteLog;
                'Verbosity' = $Verbosity;
                'InformationAction' = $InformationAction;
                'returnData' = $Script:returnData;
            }
        }
        #Split plugins to avoid Throttle in Exchange Online
        $EXO_Plugins = $O365Object.Plugins | Where-Object {$_.File.DirectoryName -like "*exchange_online*" -or $_.File.DirectoryName -like "*security_compliance*"} | Select-Object -ExpandProperty File
        $M365_Rest_Plugins = $O365Object.Plugins | Where-Object {$_.File.DirectoryName -notlike "*exchange_online*" -and $_.File.DirectoryName -notlike "*security_compliance*"} | Select-Object -ExpandProperty File
        #Check if Exchange online plugins are present
        if(@($EXO_Plugins).Count -gt 0){
            $params = @{
                ImportPlugins = $EXO_Plugins;
                ImportVariables = $vars;
                ImportCommands = $O365Object.libutils;
                ImportModules = $O365Object.runspaces_modules;
                StartUpScripts = $O365Object.exo_runspace_init;
                ThrowOnRunspaceOpenError = $true;
                Debug = $O365Object.VerboseOptions.Debug;
                Verbose = $O365Object.VerboseOptions.Verbose;
            }
            #Launch plugins
            Invoke-MonkeyRunspace @params -Throttle 1 -MaxQueue 1
        }
        #Check if rest of plugins are present
        if(@($M365_Rest_Plugins).Count -gt 0){
            $params = @{
                ImportPlugins = $M365_Rest_Plugins;
                ImportVariables = $vars;
                ImportCommands = $O365Object.libutils;
                ImportModules = $O365Object.runspaces_modules;
                StartUpScripts = $O365Object.runspace_init;
                ThrowOnRunspaceOpenError = $true;
                Debug = $O365Object.VerboseOptions.Debug;
                Verbose = $O365Object.VerboseOptions.Verbose;
                Throttle = $O365Object.threads;
                BatchSleep = $O365Object.BatchSleep;
                BatchSize = $O365Object.BatchSize;
            }
            #Launch plugins
            Invoke-MonkeyRunspace @params
        }
        $MonkeyExportObject = New-O365ExportObject
        #Prepare Output
        Out-MonkeyData -MonkeyExportObject $MonkeyExportObject
    }
}
