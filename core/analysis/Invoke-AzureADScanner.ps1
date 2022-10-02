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
        #Get Azure AD plugins
        $azure_plugins = $O365Object.Plugins | Select-Object -ExpandProperty File
        #Get Execution Info
        $O365Object.executionInfo = Get-ExecutionInfo
        #Invoke new scan
        if(@($O365Object.Plugins).Count -gt 0){
            $vars = @{
                'O365Object' = $O365Object;
                'WriteLog' = $WriteLog;
                'Verbosity' = $Verbosity;
                'InformationAction' = $InformationAction;
                'returnData' = $Script:returnData;
            }
            $params = @{
                ImportPlugins = $azure_plugins;
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
            Invoke-MonkeyRunspace @params
            $MonkeyExportObject = New-O365ExportObject
            #Prepare Output
            Out-MonkeyData -MonkeyExportObject $MonkeyExportObject
        }
    }
}
