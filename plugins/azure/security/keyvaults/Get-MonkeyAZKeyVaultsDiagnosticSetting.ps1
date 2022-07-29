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


Function Get-MonkeyAZKeyVaultsDiagnosticSetting{
    <#
        .SYNOPSIS
		Azure plugin to get all keyvaults diagnostics settings in subscription

        .DESCRIPTION
		Azure plugin to get all keyvaults diagnostics settings in subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZKeyVaultsDiagnosticSetting
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Keyvaults
        $KeyVaults = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.KeyVault/*'}
        if(-NOT $KeyVaults){continue}
        $all_diag_settings = @();
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Keyvault diagnostic settings", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureKeyVaultDiagSettingsInfo');
        }
        Write-Information @msg
        if($KeyVaults){
            foreach($keyvault in $KeyVaults){
                $URI = ("{0}{1}/providers/microsoft.insights/diagnosticSettings?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$keyvault.id,'2017-05-01-preview')
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $key_vault_diag_settings = Get-MonkeyRMObject @params
                #KeyVault diag setting object
                if($key_vault_diag_settings.id){
                    $new_key_vault_diag_settings = New-Object -TypeName PSCustomObject
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name id -value $key_vault_diag_settings.id
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name keyvaultname -value $keyvault.name
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name rawObject -value $key_vault_diag_settings
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name properties -value $key_vault_diag_settings.properties
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name name -value $key_vault_diag_settings.name
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name location -value $key_vault_diag_settings.location
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name tags -value $key_vault_diag_settings.tags
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name storageAccountId -value $key_vault_diag_settings.properties.storageAccountId
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name serviceBusRuleId -value $key_vault_diag_settings.properties.serviceBusRuleId
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name workspaceId -value $key_vault_diag_settings.properties.workspaceId
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name eventHubAuthorizationRuleId -value $key_vault_diag_settings.properties.eventHubAuthorizationRuleId
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name eventHubName -value $key_vault_diag_settings.properties.eventHubName
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name logAnalyticsDestinationType -value $key_vault_diag_settings.properties.logAnalyticsDestinationType
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name logCategory -value $key_vault_diag_settings.properties.logs.category
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name logsEnabled -value $key_vault_diag_settings.properties.logs.enabled
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name logsRetentionPolicy -value $key_vault_diag_settings.properties.logs.retentionPolicy.enabled
                    $new_key_vault_diag_settings | Add-Member -type NoteProperty -name logsRetentionPolicyDays -value $key_vault_diag_settings.properties.logs.retentionPolicy.days
                    #Add keyvault to array
                    $all_diag_settings += $new_key_vault_diag_settings
                }
            }
        }
    }
    End{
        if($all_diag_settings){
            $all_diag_settings.PSObject.TypeNames.Insert(0,'Monkey365.Azure.key_vaults.diagnostic_settings')
            [pscustomobject]$obj = @{
                Data = $all_diag_settings
            }
            $returnData.az_key_vaults_diag_settings = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure keyvault diagnostic settings", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureKeyVaultDiagSettingsEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
