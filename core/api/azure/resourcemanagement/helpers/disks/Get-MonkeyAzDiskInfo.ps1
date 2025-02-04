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

Function Get-MonkeyAzDiskInfo {
    <#
        .SYNOPSIS
		Get disk metadata from Azure

        .DESCRIPTION
		Get disk metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzDiskInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2024-03-02"
    )
    Process{
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Azure Disk");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureDiskInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $disk = Get-MonkeyAzObjectById @p
            if($null -ne $disk){
                $diskObject = $disk | New-MonkeyDiskObject
                #Get Locks
                $diskObject.locks = $diskObject | Get-MonkeyAzLockInfo
                #Get OS disk Encryption status
				If ($null -ne $diskObject.properties.PSObject.Properties.Item('encryptionSettingsCollection')) {
					If ($diskObject.properties.encryptionSettingsCollection.enabled -eq $true) {
						$diskObject.encryption.osDiskEncryption = $True
					}
					Else {
						$diskObject.encryption.osDiskEncryption = $false
					}
				}
				Else {
					$diskObject.encryption.osDiskEncryption = $false
				}
                #Get data access auth mode
                If ($null -ne $diskObject.properties.PSObject.Properties.Item('dataAccessAuthMode')) {
					$diskObject.dataAccessAuthMode = $diskObject.properties.dataAccessAuthMode;
				}
                Else{
                    $diskObject.dataAccessAuthMode = "None"
                }
                #Return object
                return $diskObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
