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

Function Get-MonkeyAzVMOSDataDiskInfo {
    <#
        .SYNOPSIS
		Get Azure VM OS data disk info

        .DESCRIPTION
		Get Azure VM OS data disk info

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
            if($InputObject.Properties.storageProfile.dataDisks.Count -gt 0){
                foreach ($data_disk in $InputObject.Properties.storageProfile.dataDisks) {
                    $diskEncryption = $InputObject.instanceView.disks.Where({$_.Name -eq $data_disk.name}) | Select-Object -ExpandProperty encryptionSettings -ErrorAction Ignore
                    if($null -ne $diskEncryption){
                        $data_disk | Add-Member -Type NoteProperty -Name isEncrypted -Value $true
                    }
                    else{
                        $data_disk | Add-Member -Type NoteProperty -Name isEncrypted -Value $false
                    }
                    #Check if managed disk
                    if ($null -ne $data_disk.PSObject.Properties.Item('managedDisk')) {
                        $data_disk | Add-Member -Type NoteProperty -Name isManaged -Value $true
                        #Get disk
                        $p = @{
			                Id = $data_disk.managedDisk.Id;
                            ApiVersion = $AzureDiskConfig.api_version;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
		                }
		                $rawDisk = Get-MonkeyAzObjectById @p
                        if($rawDisk){
                            $data_disk | Add-Member -Type NoteProperty -Name disk -Value $rawDisk
                            #Get SSE encryption
                            $sseObject = [PSCustomObject]@{
                                type = $rawDisk.Properties.encryption.type;
                                properties = $null;
                            }
                            $data_disk | Add-Member -Type NoteProperty -Name SSE -Value $sseObject
                            if ($null -ne $rawDisk.Properties.encryption.PSObject.Properties.Item('diskEncryptionSetId')) {
                                $p = @{
		                            Id = $rawDisk.properties.encryption.diskEncryptionSetId;
                                    ApiVersion = $AzureDiskConfig.api_version;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                    InformationAction = $O365Object.InformationAction;
	                            }
	                            $data_disk.SSE.properties = Get-MonkeyAzObjectById @p
                            }
                        }
                        else{
                            $data_disk | Add-Member -Type NoteProperty -Name disk -Value $null
                            $sseObject = [PSCustomObject]@{
                                type = $null;
                                properties = $null;
                            }
                            $data_disk | Add-Member -Type NoteProperty -Name SSE -Value $sseObject
                        }
                    }
                    else{
                        $data_disk | Add-Member -Type NoteProperty -Name isManaged -Value $false
                    }
                    #Get data access auth mode
                    If($null -ne $data_disk.disk){
                        If ($null -eq $data_disk.disk.properties.PSObject.Properties.Item('dataAccessAuthMode')) {
					        $data_disk.disk.properties | Add-Member -Type NoteProperty -Name dataAccessAuthMode -Value "None"
				        }
                    }
                    #Add to array
                    $InputObject.dataDisks.Add($data_disk)
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
