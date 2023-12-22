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

Function Get-MonkeyAzVMOSDiskInfo {
    <#
        .SYNOPSIS
		Get Azure VM OS disk info

        .DESCRIPTION
		Get Azure VM OS disk info

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVMOSDiskInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="VM object")]
        [Object]$InputObject
    )
    Begin{
        #Get Azure Storage Auth
		$AzureDiskConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureDisk" } | Select-Object -ExpandProperty resource
    }
    Process{
        try{
            $osDisk = $InputObject.Properties.storageProfile.osDisk
            if ($osDisk) {
                $InputObject.osDisk.rawObject = $osDisk;
                #Check if encrypted OS disk
	            $diskEncryption = $InputObject.Properties.instanceView.disks.Where({$_.Name -eq $osDisk.name}) | Select-Object -ExpandProperty encryptionSettings -ErrorAction Ignore
	            if ($null -ne $diskEncryption) {
		            if ($diskEncryption.enabled -eq $true) {
                        $InputObject.osDisk.isEncrypted = $true;
		            }
		            else {
			            $InputObject.osDisk.isEncrypted = $false;
		            }
	            }
	            else {
		            $InputObject.osDisk.isEncrypted = $false;
	            }
                #Check if managed OS disk
                if ($null -ne $osDisk.PSObject.Properties.Item('managedDisk')) {
                    $InputObject.osDisk.isManagedDisk = $true;
                    #Get managed disk info
                    $p = @{
		                Id = $osDisk.managedDisk.Id;
                        ApiVersion = $AzureDiskConfig.api_version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $InputObject.osDisk.disk = Get-MonkeyAzObjectById @p
                    if($null -ne $InputObject.osDisk.disk){
                        $InputObject.osDisk.SSE.type = $InputObject.osDisk.disk.properties.encryption.type;
                        if ($null -ne $InputObject.osDisk.disk.properties.encryption.PSObject.Properties.Item('diskEncryptionSetId')) {
                            $p = @{
		                        Id = $InputObject.osDisk.disk.properties.encryption.diskEncryptionSetId;
                                ApiVersion = $AzureDiskConfig.api_version;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
	                        }
	                        $InputObject.osDisk.SSE.properties = Get-MonkeyAzObjectById @p
                        }
                    }
                }
                else{
                    $InputObject.osDisk.isManagedDisk = $false;
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}