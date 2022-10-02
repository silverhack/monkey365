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
        #Set excluded auth var
        $ExcludedAuths = @("certificate_credentials","client_credentials")
        if($ExcludedAuths -contains $O365Object.AuthType){
            $excluded = $true
        }
        else{
            $excluded = $false
        }
        #Set selected_plugins array
        $selected_plugins = @()
        #Get all plugin metadata
        $all_plugin_metadata = Get-MetadataFromPlugin
        $targeted_analysis = $O365Object.initParams.Analysis
    }
    Process{
        if($null -ne $all_plugin_metadata -and $null -ne $targeted_analysis){
            foreach($element in $targeted_analysis.GetEnumerator()){
                if($element -eq 'All'){
                    $selected_plugins = $all_plugin_metadata | Where-Object {$_.Provider -eq $O365Object.Instance}
                    break;
                }
                else{
                    $discovered_plugins = $all_plugin_metadata | Where-Object {$_.Provider -eq $O365Object.Instance -and $_.Group.Contains($element)}
                    if($discovered_plugins){
                        $selected_plugins+=$discovered_plugins
                    }
                }
            }
        }
        #Check if should load AzureAD plugins
        $discovered_plugins = $null
        if($null -ne $all_plugin_metadata -and $O365Object.IncludeAAD -eq $true){
            if([System.Convert]::ToBoolean($O365Object.internal_config.azuread.useAzurePortalAPI) -and $excluded -eq $false){
                #Load AzureADPortal and LegacyO365API plugins
                $discovered_plugins = $all_plugin_metadata | Where-Object {$_.Provider -eq "AzureAD" -and ($_.Group.Contains("AzureADPortal") -or $_.Group.Contains("LegacyO365API"))}
            }
            else{
                #Load legacy Graph and MSGraph plugins
                $discovered_plugins = $all_plugin_metadata | Where-Object {$_.Provider -eq "AzureAD" -and $_.Group.Contains("AzureAD")}
            }
            if($null -ne $discovered_plugins){
                #Check if dump users with internal Graph API
                if([System.Convert]::ToBoolean($O365Object.internal_config.azuread.dumpAdUsersWithInternalGraphAPI) -and $excluded -eq $false){
                    #Remove users from selected plugins
                    $discovered_plugins = $discovered_plugins | Where-Object {$_.PluginName -ne "Get-MonkeyADUser"}
                    #Add graph users plugin
                    $ad_users_plugin = $all_plugin_metadata | Where-Object {$_.Provider -eq "AzureAD" -and ($_.Group.Contains("AzureAD") -and $_.PluginName -eq "Get-MonkeyADUser")}
                    if($ad_users_plugin){
                        $discovered_plugins+=$ad_users_plugin
                    }
                }
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
                InformationAction = $script:InformationAction;
                Tags = @('ExcludeAzureResourceFromScanning');
            }
            #Write-Warning @msg
            Write-Warning $message
            $selected_plugins = $selected_plugins | Where-Object {$_.Id -notin $O365Object.excludePlugins}
        }
        return $selected_plugins | Sort-Object -Property Id -Unique
    }
}