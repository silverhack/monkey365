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


Function Get-MonkeyAZRMVM{
    <#
        .SYNOPSIS
		Plugin to get information related from Resource Manager VM from Azure

        .DESCRIPTION
		Plugin to get information related from Resource Manager VM from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZRMVM
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
        #Get Config
        $AzureVMConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureVm"} | Select-Object -ExpandProperty resource
        #Get Azure Storage Auth
        $AzureDiskConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureDisk"} | Select-Object -ExpandProperty resource
        #Get VMs
        $vms_v2 = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Compute/virtualMachines'}
        if(-NOT $vms_v2){continue}
        #set array
        $vms = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Virtual machines", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureVMInfo');
        }
        Write-Information @msg
        if($vms_v2){
            foreach($rmvm in $vms_v2){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $rmvm.name, "Virtual machine");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureVMInfo');
                }
                Write-Information @msg
                #Construct URI
                $URI = ('{0}{1}?api-version={2}&$expand=instanceView' `
                        -f $O365Object.Environment.ResourceManager, `
                            $rmvm.id,$AzureVMConfig.api_version)
                #launch request
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $vm = Get-MonkeyRMObject @params
                if($vm.id){
                    #Check for antimalware
                    $av = $vm | Where-Object {$_.resources.id -match "IaaSAntimalware" -and $_.properties.storageProfile.osDisk.osType -eq "Windows"}
                    if($av){
                        $vm | Add-Member -type NoteProperty -name antimalwareAgent -value $true
                    }
                    else{
                        $vm | Add-Member -type NoteProperty -name antimalwareAgent -value $false
                    }
                    #Check for installed agent
                    $agent = $vm | Where-Object {$_.resources.id -match "MicrosoftMonitoringAgent" -or $_.resources.id -match "OmsAgentForLinux"}
                    if($agent){
                        $vm | Add-Member -type NoteProperty -name vmagentinstalled -value $true
                    }
                    else{
                        $vm | Add-Member -type NoteProperty -name vmagentinstalled -value $false
                    }
                    #Get OS disk encryption
                    $osDiskName = $vm.properties.storageProfile.osDisk.name
                    if($osDiskName){
                        $diskEncryption = $vm.properties.instanceView.disks | Where-Object {$_.name -eq $osDiskName} | Select-Object -ExpandProperty encryptionSettings -ErrorAction Ignore
                        if($null -ne $diskEncryption){
                            if($diskEncryption.enabled -eq $true){
                                $vm | Add-Member -type NoteProperty -name os_disk_encryption -value "Enabled"
                            }
                            else{
                                $vm | Add-Member -type NoteProperty -name os_disk_encryption -value "Disabled"
                            }
                        }
                        else{
                            $vm | Add-Member -type NoteProperty -name os_disk_encryption -value "Disabled"
                        }
                    }
                    #Check if OS is a managed disk
                    $osDisk = $vm.properties.storageProfile.osDisk
                    if($null -ne $osDisk){
                        if($null -ne $osDisk.psobject.Properties.Item('managedDisk')){
                            $vm | Add-Member -type NoteProperty -name os_managed_disk -value $true
                            #Get os disk info
                            $URI = ("{0}{1}?api-version={2}" `
                                    -f $O365Object.Environment.ResourceManager, `
                                        $osDisk.managedDisk.id,$AzureDiskConfig.api_version)

                            $params = @{
                                Authentication = $rm_auth;
                                OwnQuery = $URI;
                                Environment = $Environment;
                                ContentType = 'application/json';
                                Method = "GET";
                            }
                            $managed_disk = Get-MonkeyRMObject @params
                            if($null -ne $managed_disk){
                                #Get SSE encryption status
                                $vm | Add-Member -type NoteProperty -name os_sse_encryption -value $managed_disk.properties.encryption.type
                                #Check if key is auto-rotate
                                if($null -ne $managed_disk.properties.encryption.psobject.properties.Item('diskEncryptionSetId')){
                                    #Get SSE Encryption Set
                                    $URI = ("{0}{1}?api-version={2}" `
                                            -f $O365Object.Environment.ResourceManager, `
                                                $managed_disk.properties.encryption.diskEncryptionSetId,$AzureDiskConfig.api_version)

                                    $params = @{
                                        Authentication = $rm_auth;
                                        OwnQuery = $URI;
                                        Environment = $Environment;
                                        ContentType = 'application/json';
                                        Method = "GET";
                                    }
                                    $SSE_Encryption_Set = Get-MonkeyRMObject @params
                                    if($null -ne $SSE_Encryption_Set){
                                        $vm | Add-Member -type NoteProperty -name os_sse_encryption_set -value $SSE_Encryption_Set
                                    }
                                }
                                else{
                                    $vm | Add-Member -type NoteProperty -name os_sse_encryption_set -value $null
                                }
                            }
                        }
                        else{
                            $vm | Add-Member -type NoteProperty -name os_managed_disk -value $false
                            #Set OS SSE encryption status to null
                            $vm | Add-Member -type NoteProperty -name os_sse_encryption -value $null
                            $vm | Add-Member -type NoteProperty -name os_sse_encryption_set -value $null
                        }
                    }
                    $dataDisks = $vm.properties.storageProfile.dataDisks
                    if($null -ne $dataDisks){
                        #Create array
                        $all_data_disks = @()
                        #Count Data Disks
                        $vm | Add-Member -type NoteProperty -name os_data_disk_number -value $dataDisks.Count
                        foreach($data_disk in $dataDisks){
                            $dd_name = $data_disk.name
                            if($null -ne $dd_name){
                                #Create new PsObject
                                $data_disks_info = New-Object -TypeName PSCustomObject
                                $data_disks_info | Add-Member -type NoteProperty -name name -value $dd_name
                                $diskEncryption = $vm.properties.instanceView.disks | Where-Object {$_.name -eq $dd_name} | Select-Object -ExpandProperty encryptionSettings -ErrorAction Ignore
                                if($null -ne $diskEncryption){
                                    if($diskEncryption.enabled -eq $true){
                                        $data_disks_info | Add-Member -type NoteProperty -name disk_encryption -value "Enabled"
                                    }
                                    else{
                                        $data_disks_info | Add-Member -type NoteProperty -name disk_encryption -value "Disabled"
                                    }
                                }
                                else{
                                    $data_disks_info | Add-Member -type NoteProperty -name disk_encryption -value "Disabled"
                                }
                                #Check if data disks are managed disks
                                if($null -ne $data_disk.psobject.Properties.Item('managedDisk')){
                                    $data_disks_info | Add-Member -type NoteProperty -name is_managed_disk -value $true
                                    #Get managed disk info
                                    $URI = ("{0}{1}?api-version={2}" `
                                            -f $O365Object.Environment.ResourceManager, `
                                                $data_disk.managedDisk.id,$AzureDiskConfig.api_version)

                                    $params = @{
                                        Authentication = $rm_auth;
                                        OwnQuery = $URI;
                                        Environment = $Environment;
                                        ContentType = 'application/json';
                                        Method = "GET";
                                    }
                                    $managed_disk = Get-MonkeyRMObject @params
                                    if($null -ne $managed_disk){
                                        #Get SSE encryption status
                                        $data_disks_info | Add-Member -type NoteProperty -name sse_encryption -value $managed_disk.properties.encryption.type
                                        #Check if key is auto-rotate
                                        if($null -ne $managed_disk.properties.encryption.psobject.properties.Item('diskEncryptionSetId')){
                                            #Get SSE Encryption Set
                                            $URI = ("{0}{1}?api-version={2}" `
                                                    -f $O365Object.Environment.ResourceManager, `
                                                        $managed_disk.properties.encryption.diskEncryptionSetId,$AzureDiskConfig.api_version)

                                            $params = @{
                                                Authentication = $rm_auth;
                                                OwnQuery = $URI;
                                                Environment = $Environment;
                                                ContentType = 'application/json';
                                                Method = "GET";
                                            }
                                            $SSE_Encryption_Set = Get-MonkeyRMObject @params
                                            if($null -ne $SSE_Encryption_Set){
                                                $data_disks_info | Add-Member -type NoteProperty -name sse_encryption_set -value $SSE_Encryption_Set
                                            }
                                        }
                                        else{
                                            $data_disks_info | Add-Member -type NoteProperty -name sse_encryption_set -value $null
                                        }
                                    }
                                }
                                else{
                                    $data_disks_info | Add-Member -type NoteProperty -name is_managed_disk -value $false
                                    #Set SSE encryption to null
                                    $data_disks_info | Add-Member -type NoteProperty -name sse_encryption -value $null
                                    $data_disks_info | Add-Member -type NoteProperty -name sse_encryption_set -value $null
                                }
                            }
                            #Add to array
                            $all_data_disks+=$data_disks_info
                        }
                    }
                    #Set Data disk encryption
                    $vm | Add-Member -type NoteProperty -name data_disks -value $all_data_disks
                    #Get network interfaces
                    $NetworkInterface = $vm.properties.networkprofile.networkInterfaces.id
                    if($NetworkInterface){
                        $URI = ('{0}{1}?api-version={2}' -f $O365Object.Environment.ResourceManager, $NetworkInterface, '2016-03-30')
                        #Perform Query
                        $params = @{
                            Authentication = $rm_auth;
                            OwnQuery = $URI;
                            Environment = $Environment;
                            ContentType = 'application/json';
                            Method = "GET";
                        }
                        $Result = Get-MonkeyRMObject @params
                        if($Result.name){
                            $vm | Add-Member -type NoteProperty -name InterfaceName -value $Result.name
                            $vm | Add-Member -type NoteProperty -name LocalIPAddress -value $Result.properties.ipConfigurations.properties.privateIPAddress
                            $vm | Add-Member -type NoteProperty -name MACAddress -value $Result.properties.macAddress
                            $vm | Add-Member -type NoteProperty -name IPForwardingEnabled -value $Result.properties.enableIPForwarding
                            $PublicIPEndPoint = $Result.properties.ipConfigurations.properties.publicIPAddress.id
                            if($PublicIPEndPoint){
                                $URI =  ('{0}{1}?api-version={2}' -f $O365Object.Environment.ResourceManager, $PublicIPEndPoint, '2016-12-01')
                                $params = @{
                                    Authentication = $rm_auth;
                                    OwnQuery = $URI;
                                    Environment = $Environment;
                                    ContentType = 'application/json';
                                    Method = "GET";
                                }
                                $PublicIP = Get-MonkeyRMObject @params
                                if($PublicIP.properties){
                                    $vm | Add-Member -type NoteProperty -name PublicIPAddress -value $PublicIP.properties.ipAddress
                                    $vm | Add-Member -type NoteProperty -name publicIPAllocationMethod -value $PublicIP.properties.publicIPAllocationMethod
                                }
                            }
                        }
                    }
                    #Add to object
                    $vms+=$vm
                }
            }
        }
    }
    End{
        if($vms){
            $vms.PSObject.TypeNames.Insert(0,'Monkey365.Azure.VirtualMachines')
            [pscustomobject]$obj = @{
                Data = $vms
            }
            $returnData.az_virtual_machines = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Virtual machines", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureVMEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
