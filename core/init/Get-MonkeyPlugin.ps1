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

Function Get-MonkeyPlugin{
    <#
        .SYNOPSIS
        Utility to work with internal plugins
        .DESCRIPTION
        Utility to work with internal plugins
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyPlugin
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    Begin{
        #Set arrays
        $selected_plugins = @()
        $available_plugins = @()
        #Get all plugin metadata
        try{
            $all_plugin_metadata = Get-MetadataFromPlugin
            #Remove disabled plugins
            $all_plugin_metadata = $all_plugin_metadata | Where-Object {$null -ne $_.Tags -and $null -ne $_.Tags.Item('enabled') -and $_.Tags.Item('enabled') -eq $true}
        }
        catch{
            $errorMessage = @{
                Message      = $_.Exception.Message
                Category     = [System.Management.Automation.ErrorCategory]::InvalidData
                ErrorId      = 'Monkey365PluginError'
            }
            $msg = @{
                MessageData = $errorMessage;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365PluginError');
            }
            Write-Error @msg
            $all_plugin_metadata = @()
        }
        $targeted_analysis = $O365Object.initParams.Analysis
        #Remove plugins for services that are not available
        foreach($service in $O365Object.onlineServices.GetEnumerator()){
            if($service.Value -eq $true){
                $_plugins = $all_plugin_metadata | Where-Object {$_.Group.Contains($service.Name) -or $_.Provider -eq $service.Name}
                if($_plugins){
                    $available_plugins+=$_plugins
                }
            }
        }
        try{
            $useMsGraph = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.useMsGraph)
            $useAADOldAPIForUsers = [System.Convert]::ToBoolean($O365Object.internal_config.azuread.provider.graph.getUsersWithAADInternalAPI)
        }
        catch{
            $useMsGraph = $true;
            $useAADOldAPIForUsers = $false;
        }
    }
    Process{
        if($available_plugins.Count -gt 0 -and $null -ne $targeted_analysis){
            foreach($element in $targeted_analysis.GetEnumerator()){
                if($element -eq 'All'){
                    $selected_plugins = $available_plugins | Where-Object {$_.Provider -eq $O365Object.Instance}
                    break;
                }
                else{
                    $discovered_plugins = $available_plugins | Where-Object {$_.Provider -eq $O365Object.Instance -and $_.Group.Contains($element)}
                    if($discovered_plugins){
                        $selected_plugins+=$discovered_plugins
                    }
                }
            }
        }
        #Check if should load AzureAD plugins
        $discovered_plugins = $null
        if($available_plugins.Count -gt 0 -and $O365Object.IncludeAAD -eq $true){
            if($O365Object.isConfidentialApp -eq $true){
                #Load MSGraph plugins
                $discovered_plugins = $available_plugins | Where-Object {$_.Provider -eq "AzureAD" -and $_.ApiType -eq 'MSGraph'}
                #Add PIM plugins
                $PIM_plugins = $available_plugins | Where-Object {$_.Provider -eq "AzureAD" -and ($_.ApiType -eq 'PIM')}
                if($PIM_plugins){
                    $discovered_plugins+=$PIM_plugins
                }
            }
            elseif($useMsGraph -eq $false -and $O365Object.isConfidentialApp -eq $false){
                #Load Old Graph plugins and Azure AD internal API plugins
                $discovered_plugins = $available_plugins | Where-Object {$_.Provider -eq "AzureAD" -and ($_.ApiType -eq 'Graph' -or $_.ApiType -eq 'AzureADPortal')}
            }
            elseif($useMsGraph -and $O365Object.isConfidentialApp -eq $false){
                #Load MS Graph plugins and Azure AD internal API plugins
                $discovered_plugins = $available_plugins | Where-Object {$_.Provider -eq "AzureAD" -and ($_.ApiType -eq 'MSGraph' -or $_.ApiType -eq 'AzureADPortal')}
                #Check if should load old AAD plugin for users
                if($useAADOldAPIForUsers){
                    #Remove MSGraph user plugin
                    $discovered_plugins = $discovered_plugins | Where-Object {$_.PluginName -ne "Get-MonkeyAADUser"}
                    #Add graph users plugin
                    $ad_users_plugin = $available_plugins | Where-Object {$_.Provider -eq "AzureAD" -and ($_.ApiType -eq 'Graph' -and $_.PluginName -eq "Get-MonkeyADUser")}
                    if($ad_users_plugin){
                        $discovered_plugins+=$ad_users_plugin
                    }
                }
                #Add graph ad policy plugin
                $ad_policy_plugin = $available_plugins | Where-Object {$_.Provider -eq "AzureAD" -and ($_.ApiType -eq 'Graph' -and $_.PluginName -eq "Get-MonkeyADPolicy")}
                if($ad_policy_plugin){
                    $discovered_plugins+=$ad_policy_plugin
                }
                #Add PIM plugins
                $PIM_plugins = $available_plugins | Where-Object {$_.Provider -eq "AzureAD" -and $_.ApiType -eq 'PIM'}
                if($PIM_plugins){
                    $discovered_plugins+=$PIM_plugins
                }
            }
            else{
                #Load MSGraph plugins
                $discovered_plugins = $available_plugins | Where-Object {$_.Provider -eq "AzureAD" -and $_.ApiType -eq 'MSGraph'}
            }
            #Add discovered plugins
            if($null -ne $discovered_plugins){
                $selected_plugins+=$discovered_plugins
            }
        }
    }
    End{
        #Exclude plugins if present
        if($null -ne $O365Object.excludePlugins){
            $message = ("The following plugins will be excluded: {0}" -f [string]::join(",", $O365Object.excludePlugins))
            $msg = @{
                MessageData = $message;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('ExcludeAzureResourceFromScanning');
            }
            #Write-Warning @msg
            Write-Warning $msg
            $selected_plugins = $selected_plugins | Where-Object {$_.Id -notin $O365Object.excludePlugins}
        }
        return $selected_plugins | Sort-Object -Property Id -Unique
    }
}