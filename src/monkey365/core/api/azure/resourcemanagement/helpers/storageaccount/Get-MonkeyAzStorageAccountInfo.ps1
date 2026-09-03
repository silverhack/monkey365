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

Function Get-MonkeyAzStorageAccountInfo {
    <#
        .SYNOPSIS
		Get storage account metadata from Azure

        .DESCRIPTION
		Get storage account metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzStorageAccountInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Storage account object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-08-01"
    )
    Process{
        try{
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $strAccount = Get-MonkeyAzObjectById @p
            if($strAccount){
                $strObject = $strAccount | New-MonkeyStorageAccountObject
                #Format keys
                $strObject = $strObject | Format-StorageAccountKeyCreation
                #Get KeyVault info from storage account
				If ($null -ne $strObject.properties.encryption.PSObject.Properties.Item('keyvaultproperties') -and $strObject.properties.encryption.keyvaultproperties) {
					$strObject.encryption.keyVault.keyvaulturi = $strObject.properties.encryption.keyvaultproperties | Select-Object -ExpandProperty keyvaulturi -ErrorAction Ignore
					$strObject.encryption.keyVault.keyname = $strObject.Properties.encryption.keyvaultproperties | Select-Object -ExpandProperty keyname -ErrorAction Ignore
					$strObject.encryption.keyVault.keyversion = $strObject.Properties.encryption.keyvaultproperties | Select-Object -ExpandProperty keyversion -ErrorAction Ignore
					$strObject.encryption.keyVault.enabled = $true
				}
				#Get Storage account data protection
				$p = @{
					InputObject = $strObject;
					APIVersion = $APIVersion;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$strObject = Get-MonkeyAzStorageAccountDataProtection @p
                #Get Storage account file protection policies
				$p = @{
					Id = $strObject.id;
					APIVersion = $APIVersion;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$strObject.fileProtection = Get-MonkeyAzStorageAccountFileProtection @p
				#Get Storage account ATP settings
				$p = @{
					Resource = $strObject;
					APIVersion = "2019-01-01";
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$atp = Get-MonkeyAzAdvancedThreatProtection @p
				If ($atp) {
					$strObject.threatProtection.advancedProtection.enabled = $atp.properties | Select-Object -ExpandProperty isEnabled -ErrorAction Ignore
					$strObject.threatProtection.advancedProtection.rawObject = $atp
				}
                #Get Storage account Defender settings
				$p = @{
					InputObject = $strObject;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$strObject.threatProtection.defenderForStorage = Get-MonkeyAzDefenderForStorageSetting @p
				#Get Diagnostic settings for file
				$p = @{
					StorageAccount = $strObject;
					type = "file";
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$strObject.diagnosticSettings.file = Get-MonkeyAzStorageAccountDiagnosticSetting @p
				#Get queue diagnostic settings
				$p = @{
					StorageAccount = $strObject;
					type = "queue";
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$strObject.diagnosticSettings.queue = Get-MonkeyAzStorageAccountDiagnosticSetting @p
				#Get blob diagnostic settings
				$p = @{
					StorageAccount = $strObject;
					type = "blob";
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$strObject.diagnosticSettings.blob = Get-MonkeyAzStorageAccountDiagnosticSetting @p
				#Get table diagnostic settings
				$p = @{
					StorageAccount = $strObject;
					type = "table";
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$strObject.diagnosticSettings.table = Get-MonkeyAzStorageAccountDiagnosticSetting @p
				# Get container info
                $p = @{
			        InputObject = $strObject;
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
                $strObject.dataStorage.containers = Get-MonkeyAzStorageAccountContainerInfo @p
                # Get file shares
                $p = @{
			        Id = $strObject.id;
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
                $strObject.dataStorage.fileShares = Get-MonkeyAzStorageAccountFileShare @p
				#Check if key reminders is set
				If ($null -ne $strObject.properties.PSObject.Properties.Item('keyPolicy')) {
					$strObject.keys.keyPolicy.keyExpirationPeriodInDays = $strObject.properties.keyPolicy | Select-Object -ExpandProperty keyExpirationPeriodInDays -ErrorAction Ignore
                    $strObject.keys.keyPolicy.enableAutoRotation = $strObject.properties.keyPolicy | Select-Object -ExpandProperty enableAutoRotation -ErrorAction Ignore
				}
                #Get locks
                $strObject.locks = $strObject | Get-MonkeyAzLockInfo
                #Get potential SFTP local users
                $p = @{
			        Id = $strObject.Id;
                    Resource = "localusers";
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
		        $strObject.sftp.localUsers = Get-MonkeyAzObjectById @p
                #Get Private Endpoint connections for storage account
                $p = @{
                    InputObject = $strObject;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $strObject.networking.privateEndpointConnections = Get-MonkeyAzGenericPrivateEndpoint @p
                #Get network security perimeter for storage account
                $p = @{
                    Id = $strObject.Id;
                    Resource = "networkSecurityPerimeterConfigurations";
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $strObject.networking.networkSecurityPerimeterConfigurations = Get-MonkeyAzObjectById @p
				#return object
				return $strObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
