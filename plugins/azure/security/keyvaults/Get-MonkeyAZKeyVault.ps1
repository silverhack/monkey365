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


Function Get-MonkeyAZKeyVault{
    <#
        .SYNOPSIS
		Azure plugin to get all keyvaults in subscription

        .DESCRIPTION
		Azure plugin to get all keyvaults in subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZKeyVault
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
        #Get Azure Keyvault Auth
        $vault_auth = $O365Object.auth_tokens.AzureVault
        #Get Config
        $keyvault_Config = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureKeyVault"} | Select-Object -ExpandProperty resource
        #Get Keyvaults
        $KeyVaults = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.KeyVault/*'}
        #if(-NOT $KeyVaults){continue}
        $all_key_vaults = @();
        $all_keys = @();
        $all_secrets = @();
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure KeyVault", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureKeyVaultInfo');
        }
        Write-Information @msg
        if($KeyVaults){
            foreach($keyvault in $KeyVaults){
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$keyvault.id, `
                            $keyvault_Config.api_version)

                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $my_key_vault = Get-MonkeyRMObject @params
                #KeyVault object
                $new_key_vault_object = New-Object -TypeName PSCustomObject
                $new_key_vault_object | Add-Member -type NoteProperty -name id -value $my_key_vault.id
                $new_key_vault_object | Add-Member -type NoteProperty -name name -value $my_key_vault.name
                $new_key_vault_object | Add-Member -type NoteProperty -name tags -value $my_key_vault.tags
                $new_key_vault_object | Add-Member -type NoteProperty -name location -value $my_key_vault.location
                $new_key_vault_object | Add-Member -type NoteProperty -name properties -value $my_key_vault.properties
                $new_key_vault_object | Add-Member -type NoteProperty -name rawObject -value $my_key_vault
                $new_key_vault_object | Add-Member -type NoteProperty -name skufamily -value $my_key_vault.properties.sku.family
                $new_key_vault_object | Add-Member -type NoteProperty -name skuname -value $my_key_vault.properties.sku.name
                $new_key_vault_object | Add-Member -type NoteProperty -name tenantId -value $my_key_vault.properties.tenantId
                $new_key_vault_object | Add-Member -type NoteProperty -name vaultUri -value $my_key_vault.properties.vaultUri
                $new_key_vault_object | Add-Member -type NoteProperty -name provisioningState -value $my_key_vault.properties.provisioningState
                $new_key_vault_object | Add-Member -type NoteProperty -name enabledForDeployment -value $my_key_vault.properties.enabledForDeployment
                $new_key_vault_object | Add-Member -type NoteProperty -name enabledForDiskEncryption -value $my_key_vault.properties.enabledForDiskEncryption
                $new_key_vault_object | Add-Member -type NoteProperty -name enabledForTemplateDeployment -value $my_key_vault.properties.enabledForTemplateDeployment
                #Get Logging capabilities
                $URI = ("{0}{1}/providers/microsoft.insights/diagnosticSettings?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$my_key_vault.id,'2017-05-01-preview')

                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $key_vault_diag_settings = Get-MonkeyRMObject @params
                if($key_vault_diag_settings.id){
                    $new_key_vault_object | Add-Member -type NoteProperty -name keyvaultDagSettings -value $key_vault_diag_settings
                    $new_key_vault_object | Add-Member -type NoteProperty -name loggingEnabled -value $true
                    $new_key_vault_object | Add-Member -type NoteProperty -name logsRetentionPolicyDays -value $key_vault_diag_settings.properties.logs.retentionPolicy.days
                    if($key_vault_diag_settings.properties.storageAccountId){
                        $new_key_vault_object | Add-Member -type NoteProperty -name storageAccountId -value $key_vault_diag_settings.properties.storageAccountId
                    }
                    else{
                        $new_key_vault_object | Add-Member -type NoteProperty -name storageAccountId -value $null
                    }
                }
                else{
                    $new_key_vault_object | Add-Member -type NoteProperty -name keyvaultDagSettings -value $null
                    $new_key_vault_object | Add-Member -type NoteProperty -name loggingEnabled -value $false
                    $new_key_vault_object | Add-Member -type NoteProperty -name logsRetentionPolicyDays -value $null
                    $new_key_vault_object | Add-Member -type NoteProperty -name storageAccountId -value $null
                }
                #Get Network properties
                if(-NOT $my_key_vault.properties.networkAcls){
                    $new_key_vault_object | Add-Member -type NoteProperty -name allowAccessFromAllNetworks -value $true
                }
                elseif ($my_key_vault.properties.networkAcls.bypass -eq "AzureServices" -AND $my_key_vault.properties.networkAcls.defaultAction -eq "Allow"){
                    $new_key_vault_object | Add-Member -type NoteProperty -name allowAccessFromAllNetworks -value $true
                }
                else{
                    $new_key_vault_object | Add-Member -type NoteProperty -name allowAccessFromAllNetworks -value $false
                }
                #Get Recoverable options
                if(-NOT $my_key_vault.properties.enablePurgeProtection){
                    $new_key_vault_object | Add-Member -type NoteProperty -name enablePurgeProtection -value $false
                }
                else{
                    $new_key_vault_object | Add-Member -type NoteProperty -name enablePurgeProtection -value $my_key_vault.properties.enablePurgeProtection
                }
                if(-NOT $my_key_vault.properties.enableSoftDelete){
                    $new_key_vault_object | Add-Member -type NoteProperty -name enableSoftDelete -value $false
                }
                else{
                    $new_key_vault_object | Add-Member -type NoteProperty -name enableSoftDelete -value $my_key_vault.properties.enableSoftDelete
                }
                #Get Keys within vault
                $URI = ("{0}keys?api-version={1}" -f $my_key_vault.properties.vaultUri,'2016-10-01')

                $params = @{
                    Authentication = $vault_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $_keys = Get-MonkeyRMObject @params
                if($_keys){
                    foreach($_key in $_keys){
                        if($_key.kid){
                            $new_key = New-Object -TypeName PSCustomObject
                            $new_key | Add-Member -type NoteProperty -name keyVaultName -value $my_key_vault.name
                            $new_key | Add-Member -type NoteProperty -name keyVaultId -value $my_key_vault.id
                            $new_key | Add-Member -type NoteProperty -name id -value $_key.kid
                            $new_key | Add-Member -type NoteProperty -name enabled -value $_key.attributes.enabled
                            $new_key | Add-Member -type NoteProperty -name created -value $_key.attributes.created
                            $new_key | Add-Member -type NoteProperty -name updated -value $_key.attributes.updated
                            $new_key | Add-Member -type NoteProperty -name recoveryLevel -value $_key.attributes.recoveryLevel
                            $new_key | Add-Member -type NoteProperty -name rawObject -value $_key
                            #Check if key expires
                            if($_key.attributes.exp){
                                $new_key | Add-Member -type NoteProperty -name expires -value $_key.attributes.exp
                            }
                            else{
                                $new_key | Add-Member -type NoteProperty -name expires -value $false
                            }
                            #Add object to arrah
                            $all_keys += $new_key
                        }
                    }
                    if($all_keys){
                        $new_key_vault_object | Add-Member -type NoteProperty -name keys -value $all_keys
                    }
                    else{
                        $new_key_vault_object | Add-Member -type NoteProperty -name keys -value $null
                    }
                }
                #Get secrets within vault
                $URI = ("{0}secrets?api-version={1}" -f $my_key_vault.properties.vaultUri,'7.0')

                $params = @{
                    Authentication = $vault_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $_secrets = Get-MonkeyRMObject @params
                if($_secrets){
                    foreach($_secret in $_secrets){
                        if($_secret.id){
                            $new_secret = New-Object -TypeName PSCustomObject
                            $new_secret | Add-Member -type NoteProperty -name keyVaultName -value $my_key_vault.name
                            $new_secret | Add-Member -type NoteProperty -name keyVaultId -value $my_key_vault.id
                            $new_secret | Add-Member -type NoteProperty -name id -value $_secret.id
                            $new_secret | Add-Member -type NoteProperty -name enabled -value $_secret.attributes.enabled
                            $new_secret | Add-Member -type NoteProperty -name created -value $_secret.attributes.created
                            $new_secret | Add-Member -type NoteProperty -name updated -value $_secret.attributes.updated
                            $new_secret | Add-Member -type NoteProperty -name recoveryLevel -value $_secret.attributes.recoveryLevel
                            $new_secret | Add-Member -type NoteProperty -name rawObject -value $_secret
                            #Check if key expires
                            if($_secret.attributes.exp){
                                $new_secret | Add-Member -type NoteProperty -name expires -value $_secret.attributes.exp
                            }
                            else{
                                $new_secret | Add-Member -type NoteProperty -name expires -value $false
                            }
                            #Add object to arrah
                            $all_secrets += $new_secret
                        }
                    }
                    if($all_secrets){
                        $new_key_vault_object | Add-Member -type NoteProperty -name secrets -value $all_secrets
                    }
                    else{
                        $new_key_vault_object | Add-Member -type NoteProperty -name secrets -value $null
                    }
                }
                #Add keyvault to array
                $all_key_vaults += $new_key_vault_object
            }
        }
    }
    End{
        if($all_key_vaults){
            $all_key_vaults.PSObject.TypeNames.Insert(0,'Monkey365.Azure.KeyVaults')
            [pscustomobject]$obj = @{
                Data = $all_key_vaults
            }
            $returnData.az_key_vaults = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure KeyVaults", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureKeyVaultsEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
