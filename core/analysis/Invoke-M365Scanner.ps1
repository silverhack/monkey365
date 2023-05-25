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
    [CmdletBinding()]
    Param()
    #Get vars
    $vars = Get-MonkeyVar
    #Set vars
    $m365_plugins = [System.Collections.Generic.List[System.Object]]::new()
    $exo_non_rest_plugins = $exo_rest_plugins = $aad_plugins = $null
    #Get Azure plugins
    if($null -ne $O365Object.TenantId -and $null -ne $O365Object.Plugins){
        #Get AAD plugins
        $aad_plugins = $O365Object.Plugins.Where({$_.Provider -eq "AzureAD"}) | Select-Object -ExpandProperty File -ErrorAction Ignore
        #Get Exo legacy plugins
        $exo_non_rest_plugins = $O365Object.Plugins.Where({($_.Resource.Tolower() -eq 'exchangeonline' -or $_.Resource.ToLower() -eq 'purview') -and $_.ApiType -notcontains 'ExoApi'}) | Select-Object -ExpandProperty File -ErrorAction Ignore
        #Get Exo rest Plugins
        $exo_rest_plugins = $O365Object.Plugins.Where({($_.Resource.Tolower() -eq 'exchangeonline' -or $_.Resource.ToLower() -eq 'purview' -and ($_.ApiType -contains "ExoApi"))}) | Select-Object -ExpandProperty File -ErrorAction Ignore
        #Add to array
        foreach($pl in $exo_rest_plugins){
            [void]$m365_plugins.Add($pl);
        }
        #Get M365 plugins
        $m365_rest_plugins = $O365Object.Plugins.Where({($_.Provider.ToLower() -eq "microsoft365") -and (@('exchangeonline','purview') -notcontains $_.Resource.Tolower())}) | Select-Object -ExpandProperty File -ErrorAction Ignore
        #Add to array
        foreach($pl in $m365_rest_plugins){
            [void]$m365_plugins.Add($pl);
        }
        #Add current subscription to O365Object
        $new_subscription = [ordered]@{
            Tenant = $O365Object.Tenant
            DisplayName = $O365Object.Tenant.TenantName
            subscriptionId = $O365Object.Tenant.TenantId
        }
        $O365Object.current_subscription = $new_subscription
        #Get Execution Info
        $O365Object.executionInfo = Get-ExecutionInfo
    }
    #Set runspacePool for nested queries
    $p = @{
        Provider = "AzureAD";
        Throttle = $O365Object.threads;
    }
    $O365Object.monkey_runspacePool = New-MonkeyRunsPacePool @p
    #Set variable for nested runspaces
    $O365Object.runspace_vars = Get-MonkeyVar
    #Launch non-rest plugins scan
    if($null -ne $O365Object.TenantId -and $null -ne $exo_non_rest_plugins -and $exo_non_rest_plugins.Count -gt 0){
        #Set synchronized hashtable
        Set-Variable exoReturnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
        #Set vars
        $vars.returnData = $Script:exoReturnData;
        #Set params
        $p = @{
            ImportPlugins = $exo_non_rest_plugins;
            ImportVariables = $vars;
            ImportCommands = $O365Object.libutils;
            ImportModules = $O365Object.runspaces_modules;
            StartUpScripts = $O365Object.exo_runspace_init;
            ThrowOnRunspaceOpenError = $true;
            Debug = $O365Object.VerboseOptions.Debug;
            Verbose = $O365Object.VerboseOptions.Verbose;
        }
        #Launch plugins
        Invoke-MonkeyRunspace @p -MaxQueue 1 -Throttle 1
    }
    #Disable token renewal for purview
    if($null -ne $O365Object.o365_sessions.ComplianceCenter -and $O365Object.o365_sessions.ComplianceCenter -is [System.Management.Automation.Runspaces.PSSession]){
        $O365Object.o365_sessions.ComplianceCenter.DisableRenew()
    }
    #Execute AAD plugins
    if($null -ne $O365Object.TenantId -and $null -ne $aad_plugins){
        #Set synchronized hashtable
        Set-Variable aadReturnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
        $vars.returnData = $Script:aadReturnData;
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
            InformationAction = $O365Object.InformationAction;
            Tags = @('Monkey365SleepTime');
        }
        Write-Information @msg
        Start-Sleep -Milliseconds 10000
    }
    #execute M365 rest plugins scan
    if($null -ne $O365Object.TenantId -and $m365_plugins.Count -gt 0){
        #Set synchronized hashtable
        Set-Variable ReturnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
        #Set vars
        $vars.returnData = $Script:ReturnData;
        #Set params
        $p = @{
            ImportPlugins = $m365_plugins;
            ImportVariables = $vars;
            ImportCommands = $O365Object.libutils;
            ImportModules = $O365Object.runspaces_modules;
            StartUpScripts = $O365Object.runspace_init;
            ThrowOnRunspaceOpenError = $true;
            Debug = $O365Object.VerboseOptions.Debug;
            Verbose = $O365Object.VerboseOptions.Verbose;
        }
        #Launch plugins
        Invoke-MonkeyRunspace @p
    }
    #Cleaning Runspace
    if($null -ne $O365Object.monkey_runspacePool -and $O365Object.monkey_runspacePool -is [System.Management.Automation.Runspaces.RunspacePool]){
        #$O365Object.monkey_runspacePool.Close()
        $O365Object.monkey_runspacePool.Dispose()
        #Perform garbage collection
        [gc]::Collect()
    }
    #Combine objects
    #Check if AAD data
    if($null -ne (Get-Variable -Name aadReturnData -Scope Script -ErrorAction Ignore)){
        $Script:ReturnData = Join-HashTable -HashTable $ReturnData -JoinHashTable $aadReturnData
    }
    #Check if exo data
    if($null -ne (Get-Variable -Name exoReturnData -Scope Script -ErrorAction Ignore)){
        $Script:ReturnData = Join-HashTable -HashTable $ReturnData -JoinHashTable $exoReturnData
    }
    $MonkeyExportObject = New-O365ExportObject
    #Prepare Output
    Out-MonkeyData -MonkeyExportObject $MonkeyExportObject
}
