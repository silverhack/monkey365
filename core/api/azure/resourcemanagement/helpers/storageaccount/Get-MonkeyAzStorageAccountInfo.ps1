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
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2022-05-01"
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
                $strObject = New-MonkeyStorageAccountObject -StrAccount $strAccount
                #Check if infrastructure encryption is enabled
				if ($null -eq $strObject.Properties.encryption.PSObject.Properties.Item('requireInfrastructureEncryption')) {
					$strObject.requireInfrastructureEncryption = $false
				}
				else {
					$strObject.requireInfrastructureEncryption = $strObject.Properties.encryption.requireInfrastructureEncryption
				}
                $k1 = $strObject.Properties.keyCreationTime.key1
                if($null -ne $k1){
				    $today = Get-Date
				    $date_key1 = Get-Date $k1
				    if (($today - $date_key1).TotalDays -lt 90) {
					    $strObject.keyRotation.key1.isRotated = $true
				    }
                }
				#set key1 last rotation
				$strObject.keyRotation.key1.lastRotationDate = $strObject.Properties.keyCreationTime.key1
				$k2 = $strObject.Properties.keyCreationTime.key2
                if($null -ne $k2){
                    $date_key2 = Get-Date $k2
				    if (($today - $date_key2).TotalDays -lt 90) {
					    $strObject.keyRotation.key2.isRotated = $true
				    }
                }
				#set key2 last rotation
				$strObject.keyRotation.key2.lastRotationDate = $strObject.Properties.keyCreationTime.key2
				if ($null -ne $strObject.Properties.encryption.PSObject.Properties.Item('keyvaultproperties') -and $strObject.Properties.encryption.keyvaultproperties) {
					$strObject.keyvaulturi = $strObject.Properties.encryption.keyvaultproperties.keyvaulturi
					$strObject.keyname = $strObject.Properties.encryption.keyvaultproperties.keyname
					$strObject.keyversion = $strObject.Properties.encryption.keyvaultproperties.keyversion
					$strObject.usingOwnKey = $true
				}
				#Get Storage account data protection
				$p = @{
					StorageAccount = $strObject;
					APIVersion = "2021-06-01";
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$strObject = Get-MonkeyAzStorageAccountDataProtection @p
				#Get Storage account ATP settings
				$p = @{
					Resource = $strObject;
					APIVersion = "2017-08-01-preview";
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$atp = Get-MonkeyAzAdvancedThreatProtection @p
				if ($atp) {
					$strObject.advancedProtectionEnabled = $atp.Properties.isEnabled
					$strObject.atpRawObject = $atp
				}
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
				#Find public blobs
				$p = @{
					StorageAccount = $strObject;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$public = Find-MonkeyAzStoragePublicBlob @p
				if ($public) {
					$strObject.containers = $public
				}
				#Check if key reminders is set
				if ($null -eq $strObject.Properties.PSObject.Properties.Item('keyPolicy')) {
					$kp = @{
						keyExpirationPeriodInDays = $null;
						enableAutoRotation = $null;
					}
					$strObject.Properties | Add-Member -Type NoteProperty -Name keyPolicy -Value $kp
				}
                #Check if AllowSharedKeyAccess property
                if ($null -eq $strObject.Properties.PSObject.Properties.Item('allowSharedKeyAccess')) {
                    $strObject.Properties | Add-Member -Type NoteProperty -Name allowSharedKeyAccess -Value $true
                }
                #Get locks
                $strObject.locks = $strObject | Get-MonkeyAzLockInfo
				#return object
				return $strObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
