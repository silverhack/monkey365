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

Function Get-MonkeyCollector{
    <#
        .SYNOPSIS
        Utility to work with internal collectors
        .DESCRIPTION
        Utility to work with internal collectors
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCollector
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    Begin{
        #Set arrays
        $selected_collectors = @()
        $available_collectors = @()
        #Get all plugin metadata
        try{
            $all_collector_metadata = Get-MetadataFromCollector
            #Remove disabled plugins
            $all_collector_metadata = @($all_collector_metadata).Where({$null -ne $_.Tags -and $null -ne $_.Tags.Item('enabled') -and $_.Tags.Item('enabled') -eq $true})
        }
        catch{
            $errorMessage = @{
                Message      = $_.Exception.Message
                Category     = [System.Management.Automation.ErrorCategory]::InvalidData
                ErrorId      = 'Monkey365ConnectorError'
            }
            $msg = @{
                MessageData = $errorMessage;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365PluginError');
            }
            Write-Error @msg
            $all_collector_metadata = @()
        }
        $targeted_analysis = $O365Object.initParams.Analysis
        #Remove collectors for services that are not available
        foreach($service in $O365Object.onlineServices.GetEnumerator().Where({$_.Value -eq $true})){
            if($service.Name.ToLower() -eq 'azure' -or $service.Name.ToLower() -eq 'entraid'){
                $_plugins = $all_collector_metadata | Where-Object {$_.Provider -eq $service.Name}
            }
            else{
                $_plugins = $all_collector_metadata | Where-Object {$_.Group.Contains($service.Name)}
            }
            if($_plugins){
                $available_collectors+=$_plugins
            }
        }
        try{
            $useMsGraph = [System.Convert]::ToBoolean($O365Object.internal_config.entraId.useMsGraph)
            $useAADOldAPIForUsers = [System.Convert]::ToBoolean($O365Object.internal_config.entraId.getUsersWithAADInternalAPI)
        }
        catch{
            $useMsGraph = $true;
            $useAADOldAPIForUsers = $false;
        }
    }
    Process{
        if($available_collectors.Count -gt 0 -and $null -ne $targeted_analysis){
            foreach($element in $targeted_analysis.GetEnumerator()){
                if($element -eq 'All'){
                    $selected_collectors = @($available_collectors).Where({$_.Provider -eq $O365Object.Instance})
                    break;
                }
                else{
                    $discovered_plugins = @($available_collectors).Where({$_.Provider -eq $O365Object.Instance -and $_.Group.Tolower().Contains($element.Tolower())})
                    if($discovered_plugins){
                        $selected_collectors+=$discovered_plugins
                    }
                }
            }
        }
        #Check if should load EntraID collectors
        $discovered_plugins = $null
        if($available_collectors.Count -gt 0 -and $O365Object.IncludeEntraID -eq $true -and $O365Object.onlineServices.EntraID -eq $true){
            if($O365Object.isConfidentialApp -eq $true){
                #Load MSGraph plugins
                $discovered_plugins = @($available_collectors).Where({$_.Provider -eq "EntraID" -and $_.ApiType -eq 'MSGraph'})
            }
            elseif($useMsGraph -eq $false -and $O365Object.isConfidentialApp -eq $false){
                #Load Old Graph collectors and Azure AD internal API collectors
                $discovered_plugins = @($available_collectors).Where({$_.Provider -eq "EntraID" -and ($_.ApiType -eq 'Graph' -or $_.ApiType -eq 'EntraIDPortal')})
            }
            elseif($useMsGraph -and $O365Object.isConfidentialApp -eq $false){
                #Load Old Graph collectors and Azure AD internal API collectors
                $discovered_plugins = @($available_collectors).Where({$_.Provider -eq "EntraID" -and ($_.ApiType -eq 'MSGraph' -or $_.ApiType -eq 'EntraIDPortal')})
                #Check if should load old AAD collector for users
                if($useAADOldAPIForUsers){
                    #Remove MSGraph user collector
                    $discovered_plugins = @($discovered_plugins).Where({$_.collectorName -ne "Get-MonkeyAADUser"})
                    #Add graph users collector
                    $ad_users_plugin = @($available_collectors).Where({$_.Provider -eq "EntraID" -and ($_.ApiType -eq 'Graph' -and $_.collectorName -eq "Get-MonkeyADUser")})
                    if($ad_users_plugin){
                        $discovered_plugins+=$ad_users_plugin
                    }
                }
                #Add graph ad policy collector
                $ad_policy_plugin = @($available_collectors).Where({$_.Provider -eq "EntraID" -and ($_.ApiType -eq 'Graph' -and $_.collectorName -eq "Get-MonkeyADPolicy")})
                if($ad_policy_plugin){
                    $discovered_plugins+=$ad_policy_plugin
                }
            }
            else{
                #Load MSGraph collectors
                $discovered_plugins = @($available_collectors).Where({$_.Provider -eq "EntraID" -and $_.ApiType -eq 'MSGraph'})
            }
            #Add discovered collectors
            if($null -ne $discovered_plugins){
                $selected_collectors+=$discovered_plugins
            }
        }
    }
    End{
        #Exclude collectors if present
        if($null -ne $O365Object.excludeCollectors){
            $message = ("The following collectors will be excluded: {0}" -f [string]::join(",", $O365Object.excludeCollectors))
            $msg = @{
                MessageData = $message;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('ExcludeAzureResourceFromScanning');
            }
            Write-Verbose @msg
            $selected_collectors = @($selected_collectors).Where({$_.Id -notin $O365Object.excludeCollectors})
        }
        return $selected_collectors | Sort-Object -Property Id -Unique
    }
}