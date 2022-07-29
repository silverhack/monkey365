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


Function Get-MonkeyAZDisk{
    <#
        .SYNOPSIS
		Azure plugin to get all managed disks in subscription

        .DESCRIPTION
		Azure plugin to get all managed disks in subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZDisk
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
        #Get Azure Storage Auth
        $AzureDiskConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureDisk"} | Select-Object -ExpandProperty resource
        #Get disks
        $managed_disks = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Compute/disks'}
        if(-NOT $managed_disks){continue}
        #Set array
        $all_managed_disks = @();
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Disks", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureDiskInfo');
        }
        Write-Information @msg
        #Iterate over disks
        if($managed_disks){
            foreach($disk in $managed_disks){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $disk.name, "Disk");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureVMInfo');
                }
                Write-Information @msg
                #Construct URI
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager, `
                            $disk.id,$AzureDiskConfig.api_version)

                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $managed_disk = Get-MonkeyRMObject @params
                if($managed_disk.id){
                    $new_disk = New-Object -TypeName PSCustomObject
                    $new_disk | Add-Member -type NoteProperty -name id -value $managed_disk.id
                    $new_disk | Add-Member -type NoteProperty -name name -value $managed_disk.name
                    $new_disk | Add-Member -type NoteProperty -name location -value $managed_disk.location
                    $new_disk | Add-Member -type NoteProperty -name skuname -value $managed_disk.sku.name
                    $new_disk | Add-Member -type NoteProperty -name skutier -value $managed_disk.sku.tier
                    $new_disk | Add-Member -type NoteProperty -name ostype -value $managed_disk.properties.osType
                    $new_disk | Add-Member -type NoteProperty -name disksize -value $managed_disk.properties.diskSizeGB
                    $new_disk | Add-Member -type NoteProperty -name timecreated -value $managed_disk.properties.timeCreated
                    $new_disk | Add-Member -type NoteProperty -name provisioningState -value $managed_disk.properties.provisioningState
                    $new_disk | Add-Member -type NoteProperty -name diskState -value $managed_disk.properties.diskState
                    $new_disk | Add-Member -type NoteProperty -name managedBy -value $managed_disk.managedBy
                    $new_disk | Add-Member -type NoteProperty -name tags -value $managed_disk.tags
                    $new_disk | Add-Member -type NoteProperty -name properties -value $managed_disk.properties
                    $new_disk | Add-Member -type NoteProperty -name rawObject -value $managed_disk
                    #Get OS disk Encryption status
                    if($null -ne $managed_disk.properties.psobject.Properties.Item('encryptionSettingsCollection')){
                        if($managed_disk.properties.encryptionSettingsCollection.enabled -eq $true){
                            $new_disk | Add-Member -type NoteProperty -name os_disk_encryption -value "Enabled"
                        }
                        else{
                            $new_disk | Add-Member -type NoteProperty -name os_disk_encryption -value "Disabled"
                        }
                    }
                    else{
                        $new_disk | Add-Member -type NoteProperty -name os_disk_encryption -value "Disabled"
                    }
                    #Get SSE encryption status
                    $new_disk | Add-Member -type NoteProperty -name sse_encryption -value $managed_disk.properties.encryption.type
                    #Add to array
                    $all_managed_disks+=$new_disk
                }
            }
        }
    }
    End{
        if($all_managed_disks){
            $all_managed_disks.PSObject.TypeNames.Insert(0,'Monkey365.Azure.managed_disks')
            [pscustomobject]$obj = @{
                Data = $all_managed_disks
            }
            $returnData.az_managed_disks = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Disks", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureDiskEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
