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

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPlugin
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Begin{
        #Set excluded auth var
        $ExcludedAuths = @("certificate_credentials","client_credentials")
        if($ExcludedAuths -contains $O365Object.AuthType){
            $excluded = $true
        }
        else{
            $excluded = $false
        }
        #Set array
        $selected_plugins=@()
        #O365 Plugins
        $O365Plugins = @{
            SharepointOnline = @(
                '/plugins/o365/sharepoint_online/'
            )
            ExchangeOnline = @(
                '/plugins/o365/exchange_online/'
            )
            PurView = @(
                '/plugins/o365/security_compliance/'
            )
            EndpointManager = @(
                '/plugins/o365/EndpointManager/'
            )
            IRM = @(
                '/plugins/o365/aadrm/'
            )
            MicrosoftForms = @(
                '/plugins/o365/microsoft_forms/'
            )
            MicrosoftTeams = @(
                '/plugins/o365/teams/'
            )
        }
        #Azure AD Plugins
        $AzureADPlugins = @{
            activedirectory = @(
                '/plugins/aad/portal/'
            )
            graphad = @(
                '/plugins/aad/graph/'
            )
            LegacyO365API = @(
                '/plugins/o365/o365_legacy/'
            )
        }
        #Azure Plugins
        $AzurePlugins = @{
            domainpolicies = @(
                '/plugins/aad/graph/policies/'
            )
            databases = @(
                '/plugins/azure/databases/',
                '/plugins/azure/storageaccounts/',
                '/plugins/azure/firewall/'
            )
            virtualmachines = @(
                '/plugins/azure/virtualmachines/',
                '/plugins/azure/classicvm/',
                '/plugins/azure/security/patches/',
                '/plugins/azure/security/baseline/'
            )
            securitycenter = @(
                '/plugins/azure/security/patches/',
                '/plugins/azure/security/securitystatus/',
                '/plugins/azure/security/baseline/'
            )
            roleassignments = @(
                '/plugins/azure/security/roleassignments/'
            )
            firewall = @(
                '/plugins/azure/firewall/'
            )
            securitypolicies = @(
                '/plugins/azure/security/securitypolicies/'
            )
            missingpatches = @(
                '/plugins/azure/security/patches/'
            )
            securitybaseline = @(
                '/plugins/azure/security/baseline/'
            )
            securitycontacts = @(
                '/plugins/azure/security/securitycontacts/'
            )
            securityalerts = @(
                '/plugins/azure/alerts/'
            )
            appservices = @(
                '/plugins/azure/appservices/'
            )
            keyvaults = @(
                '/plugins/azure/security/keyvaults/'
            )
            documentdb = @("
                /plugins/azure/documentdb/"
            )
            storageaccounts = @("
                /plugins/azure/storageaccounts/"
            )
            applicationgateway = @("
                /plugins/azure/security/applicationgateway/"
            )
            custom = @("
                /plugins/custom/"
            )
        }
    }
    Process{
        try{
            #Check if should load Azure AD plugins
            if($O365Object.initParams.ContainsKey('IncludeAzureActiveDirectory') -and $O365Object.initParams.IncludeAzureActiveDirectory){
                if([System.Convert]::ToBoolean($O365Object.internal_config.azuread.useAzurePortalAPI) -and $excluded -eq $false){
                    $azure_ad_plugins = $AzureADPlugins.Item('activedirectory')
                    $azure_ad_plugins += $AzureADPlugins.Item('LegacyO365API')
                }
                else{
                    $azure_ad_plugins = $AzureADPlugins.Item('graphad')
                }
                if($azure_ad_plugins){
                    foreach($element in $azure_ad_plugins){
                        $p_path = ("{0}/{1}" -f $O365Object.Localpath, $element)
                        $params = @{
                            Path = $p_path;
                            Recurse = $true;
                            File = $true;
                            Include = "*.ps1";
                            ErrorAction = 'Ignore';
                        }
                        $selected_plugins+= Get-ChildItem @params
                    }
                }
                #Check if dump users with internal Graph API
                if([System.Convert]::ToBoolean($O365Object.internal_config.azuread.dumpAdUsersWithInternalGraphAPI) -and $excluded -eq $false){
                    $selected_plugins = $selected_plugins | Where-Object {$_.FullName -notlike "*Get-MonkeyADUser*"}
                    $u_path = ("{0}/{1}" -f $O365Object.Localpath, 'plugins/aad/graph/users/*.ps1')
                    $az_ad_users_plugin = Get-ChildItem -Path $u_path -ErrorAction Ignore
                    $selected_plugins+=$az_ad_users_plugin
                }
            }
            if($null -ne $O365Object.Instance){
                switch ($O365Object.Instance.ToLower()){
                    'azure'{
                        if($O365Object.initParams.Analysis.ToLower() -eq 'all'){
                            $p_path = ("{0}/{1}" -f $O365Object.Localpath, "plugins/azure/")
                            $params = @{
                                Path = $p_path;
                                Recurse = $true;
                                File = $true;
                                Include = "*.ps1";
                                ErrorAction = 'Ignore';
                            }
                            $selected_plugins+= Get-ChildItem @params
                        }
                        else{
                            foreach($plugin in $O365Object.initParams.Analysis.GetEnumerator()){
                                if($AzurePlugins.ContainsKey($plugin)){
                                    $pluginPaths = $AzurePlugins.Item($plugin)
                                    foreach($element in $pluginPaths){
                                        $p_path = ("{0}/{1}" -f $O365Object.Localpath, $element.Trim())
                                        $params = @{
                                            Path = $p_path;
                                            Recurse = $true;
                                            File = $true;
                                            Include = "*.ps1";
                                            ErrorAction = 'Ignore';
                                        }
                                        $selected_plugins+= Get-ChildItem @params
                                    }
                                }
                                else{
                                    Write-Warning ("Unable to find plugins for {0}" -f $plugin)
                                }
                            }
                        }
                        break;
                    }
                    'microsoft365'{
                        if($O365Object.initParams.Analysis.ToLower().Contains('all')){
                            $p_path = ("{0}/{1}" -f $O365Object.Localpath, "plugins/o365/")
                            $params = @{
                                Path = $p_path;
                                Recurse = $true;
                                File = $true;
                                Include = "*.ps1";
                                ErrorAction = 'Ignore';
                            }
                            $selected_plugins+= Get-ChildItem @params
                        }
                        else{
                            foreach($plugin in $O365Object.initParams.Analysis.GetEnumerator()){
                                if($O365Plugins.ContainsKey($plugin)){
                                    $pluginPaths = $O365Plugins.Item($plugin)
                                    foreach($element in $pluginPaths){
                                        $p_path = ("{0}/{1}" -f $O365Object.Localpath, $element)
                                        $params = @{
                                            Path = $p_path;
                                            Recurse = $true;
                                            File = $true;
                                            Include = "*.ps1";
                                            ErrorAction = 'Ignore';
                                        }
                                        $selected_plugins+= Get-ChildItem @params
                                    }
                                }
                                else{
                                    $msg = @{
                                        MessageData = ($message.UnableToGetPlugins -f $plugin);
                                        functionName = (Get-PSCallStack | Select-Object -First 1);
                                        logLevel = 'warning';
                                        Tags = @('MonkeyPluginsLoadError');
                                    }
                                    Write-Warning @msg
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
        catch{
            $msg = @{
                Message = $_;
                functionName = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                Tags = @('MonkeyPluginsLoadError');
            }
            Write-Verbose @msg
        }
    }
    End{
        if($selected_plugins){
            return $selected_plugins
        }
        else{
            return $null
        }
    }
}
