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

function Get-MonkeyAZStorageAccount {
<#
        .SYNOPSIS
		Plugin extract Storage Account information from Azure
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-https-stor-acct
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-store-file-enc

        .DESCRIPTION
		Plugin extract Storage Account information from Azure
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-https-stor-acct
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-store-file-enc

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZStorageAccount
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00040";
			Provider = "Azure";
			Resource = "StorageAccounts";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAZStorageAccount";
			ApiType = "resourceManagement";
			Title = "Plugin to get information from Azure Storage account";
			Group = @("StorageAccounts");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Config
		$strConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureStorage" } | Select-Object -ExpandProperty resource
		#Get Storage accounts
		$storage_accounts = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Storage/storageAccounts' }
        if (-not $storage_accounts) { continue }
		#Set array
		$all_str_accounts = New-Object System.Collections.Generic.List[System.Object]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Storage accounts",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureStorageAccountsInfo');
		}
		Write-Information @msg
        #Check storage accounts
        if($null -ne $storage_accounts -and @($storage_accounts).Count -gt 0){
            foreach($strAccount in @($storage_accounts)){
                $strObject = $null;
                try{
                    $msg = @{
				        MessageData = ($message.AzureUnitResourceMessage -f $strAccount.Name,"Storage account");
				        callStack = (Get-PSCallStack | Select-Object -First 1);
				        logLevel = 'info';
				        InformationAction = $O365Object.InformationAction;
				        Tags = @('AzureStorageAccountInfo');
			        }
			        Write-Information @msg
                    $p = @{
					    Id = $strAccount.Id;
                        ApiVersion = $strConfig.api_version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
				    }
				    $strAccount = Get-MonkeyAzObjectById @p
                    if($strAccount){
                        #Get new Storage account Object
                        $p = @{
					        Id = $strAccount.Id;
                            ApiVersion = $strConfig.api_version;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
				        }
                        $strObject = New-MonkeyStorageAccountObject -StrAccount $strAccount
                    }
                    if($null -ne $strObject){
                        #Check if infrastructure encryption is enabled
                        if($null -eq $strObject.properties.encryption.Psobject.Properties.Item('requireInfrastructureEncryption')){
                            $strObject.requireInfrastructureEncryption = $false
                        }
                        else{
                            $strObject.requireInfrastructureEncryption = $strObject.properties.encryption.requireInfrastructureEncryption
                        }
                        $today = Get-Date
                        $date_key1 = Get-Date $strObject.properties.keyCreationTime.key1
                        if(($today - $date_key1).TotalDays -lt 90){
                            $strObject.keyRotation.key1.isRotated = $true
                        }
                        #set key1 last rotation
                        $strObject.keyRotation.key1.lastRotationDate = $strObject.properties.keyCreationTime.key1
                        $date_key2 = Get-Date $strObject.properties.keyCreationTime.key2
                        if(($today - $date_key2).TotalDays -lt 90){
                            $strObject.keyRotation.key2.isRotated = $true
                        }
                        #set key2 last rotation
                        $strObject.keyRotation.key2.lastRotationDate = $strObject.properties.keyCreationTime.key2
                        if($null -ne $strObject.Properties.encryption.Psobject.Properties.Item('keyvaultproperties') -and $strObject.properties.encryption.keyvaultproperties){
                            $strObject.keyvaulturi = $strObject.Properties.encryption.keyvaultproperties.keyvaulturi
                            $strObject.keyname = $strObject.Properties.encryption.keyvaultproperties.keyname
                            $strObject.keyversion = $strObject.Properties.encryption.keyvaultproperties.keyversion
                            $strObject.usingOwnKey = $true
                        }
                        #Get Storage account data protection
                        $p = @{
						    StorageAccount = $strObject;
						    APIVersion = "2021-06-01";
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
					    }
                        $strObject = Get-MonkeyAzStorageAccountDataProtection @p
                        #Get Storage account ATP settings
                        $p = @{
						    Resource = $strObject;
						    APIVersion = "2017-08-01-preview";
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
					    }
                        $atp = Get-MonkeyAzAdvancedThreatProtection @p
                        if($atp){
                            $strObject.advancedProtectionEnabled = $atp.Properties.isEnabled
                            $strObject.atpRawObject = $atp
                        }
                        #Get Diagnostic settings for file
                        $p = @{
						    StorageAccount = $strObject;
						    Type = "file";
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
					    }
                        $strObject.diagnosticSettings.file = Get-MonkeyAzStorageAccountDiagnosticSetting @p
                        #Get queue diagnostic settings
                        $p = @{
						    StorageAccount = $strObject;
						    Type = "queue";
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
					    }
                        $strObject.diagnosticSettings.queue = Get-MonkeyAzStorageAccountDiagnosticSetting @p
                        #Get blob diagnostic settings
                        $p = @{
						    StorageAccount = $strObject;
						    Type = "blob";
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
					    }
                        $strObject.diagnosticSettings.blob = Get-MonkeyAzStorageAccountDiagnosticSetting @p
                        #Get table diagnostic settings
                        $p = @{
						    StorageAccount = $strObject;
						    Type = "table";
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
					    }
                        $strObject.diagnosticSettings.table = Get-MonkeyAzStorageAccountDiagnosticSetting @p
                        #Find public blobs
                        $p = @{
						    StorageAccount = $strObject;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
					    }
                        $public = Find-MonkeyAzStoragePublicBlob @p
                        if($public){
                            $strObject.containers = $public
                        }
                        #Check if key reminders is set
                        if($null -eq $strObject.properties.PsObject.Properties.Item('keyPolicy')){
                            $kp = @{
                                keyExpirationPeriodInDays = $null;
                                enableAutoRotation = $null;
                            }
                            $strObject.properties | Add-Member -Type NoteProperty -Name keyPolicy -Value $kp
                        }
                        #Add to array
                        [void]$all_str_accounts.Add($strObject)
                    }
                }
                catch{
                    Write-Error $_
                }
            }
        }
	}
	end {
		if ($all_str_accounts) {
			$all_str_accounts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.StorageAccounts')
			[pscustomobject]$obj = @{
				Data = $all_str_accounts;
				Metadata = $monkey_metadata;
			}
			$returnData.az_storage_accounts = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Storage accounts",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureStorageAccountsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




