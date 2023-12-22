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

Function Get-MonkeyAzVMScaleSetInfo {
    <#
        .SYNOPSIS
		Get Azure VM scale set info

        .DESCRIPTION
		Get Azure VM scale set info

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVMScaleSetInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="VM object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-07-01"
    )
    Process{
        try{
            $p = @{
			    Id = $InputObject.Id;
                Expand = 'userData';
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $vm = Get-MonkeyAzObjectById @p
            if($vm){
                $newVmObject = $vm | New-MonkeyVmScaleSetObject
                if($newVmObject){
                    #Get instances
                    $p = @{
					    VmObject = $newVmObject;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
				    }
                    $newVmObject.instances = Get-MonkeyVMScaleSetVM @p
                    #Get instance view
                    $p = @{
					    VmObject = $newVmObject;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
				    }
				    $newVmObject.instanceView = Get-MonkeyVMScaleSetInstanceView @p
                    #Get diagnostic settings
                    If($InputObject.supportsDiagnosticSettings -eq $True){
                        $p = @{
		                    Id = $newVmObject.Id;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
	                    }
	                    $diag = Get-MonkeyAzDiagnosticSettingsById @p
                        if($diag){
                            #Add to object
                            $newVmObject.diagnosticSettings.enabled = $true;
                            $newVmObject.diagnosticSettings.name = $diag.name;
                            $newVmObject.diagnosticSettings.id = $diag.id;
                            $newVmObject.diagnosticSettings.properties = $diag.properties;
                            $newVmObject.diagnosticSettings.rawData = $diag;
                        }
                    }
                    #######Get update config########
                    $p = @{
			            Id = $newVmObject.Id;
                        Expand = 'instanceView';
                        ApiVersion = $APIVersion;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
		            }
		            $vmConfig = Get-MonkeyAzObjectById @p
                    #Check for updates configuration
                    if($vmConfig.properties.virtualMachineProfile.storageProfile.osDisk.osType -eq 'windows'){
                        if($null -eq $vmConfig.Properties.virtualMachineProfile.osProfile.windowsConfiguration.PsObject.Properties.Item('enableAutomaticUpdates')){
                            $newVmObject.automaticUpdates.enabled = $false;
                        }
                        else{
                            $patchMode = $vmConfig.properties.virtualMachineProfile.osProfile.windowsConfiguration.patchSettings.patchMode
                            if($patchMode -eq 'Manual'){
                                $newVmObject.automaticUpdates.enabled = $false
                            }
                            else{
                                $newVmObject.automaticUpdates.enabled = $True
                            }
                        }
                        $newVmObject.automaticUpdates.rawObject = $vmConfig.Properties.osProfile;
                    }
                    else{
                        if($null -eq $vmConfig.properties.virtualMachineProfile.osProfile.linuxConfiguration.PsObject.Properties.Item('enableAutomaticUpdates')){
                            $newVmObject.automaticUpdates.enabled = $false;
                        }
                        else{
                            $patchMode = $vmConfig.properties.virtualMachineProfile.osProfile.linuxConfiguration.patchSettings.patchMode
                            if($patchMode -eq 'Manual'){
                                $newVmObject.automaticUpdates.enabled = $false
                            }
                            else{
                                $newVmObject.automaticUpdates.enabled = $True
                            }
                        }
                        $newVmObject.automaticUpdates.rawObject = $vmConfig.Properties.osProfile;
                    }
                    #Get locks
                    $newVmObject.locks = $newVmObject | Get-MonkeyAzLockInfo
                    #######Get subnets########
                    $nsgId = $newVmObject.properties.virtualMachineProfile.networkProfile.networkInterfaceConfigurations.properties.networkSecurityGroup.id
                    if($null -ne $nsgId){
                        $p = @{
			                Id = $nsgId;
                            Expand = 'subnets,networkinterfaces';
                            ApiVersion = '2021-05-01';
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
		                }
				        $newVmObject.networking = Get-MonkeyAzObjectById @p
                    }
                    else{
                        $networks = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                        foreach($ip in $newVmObject.properties.virtualMachineProfile.networkProfile.networkInterfaceConfigurations.properties.ipConfigurations){
                            $nsgId = $ip.properties.subnet.id
                            $nsgId = $nsgId.Substring(0,$nsgId.LastIndexOf("/"))
                            if($null -ne $nsgId){
                                $p = @{
			                        Id = $nsgId;
                                    Expand = 'subnets,networkinterfaces';
                                    ApiVersion = '2021-05-01';
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                    InformationAction = $O365Object.InformationAction;
		                        }
                                $subnets = Get-MonkeyAzObjectById @p
                                if($subnets){
                                    $net = $subnets.Where({$_.name -eq 'private-endpoints-snet'})
                                    if($net){
                                        $nsg = $net.properties.networkSecurityGroup.id
                                        $p = @{
			                                Id = $nsg;
                                            Expand = 'subnets,networkinterfaces';
                                            ApiVersion = '2021-05-01';
                                            Verbose = $O365Object.verbose;
                                            Debug = $O365Object.debug;
                                            InformationAction = $O365Object.InformationAction;
		                                }
                                        $mynetwork = Get-MonkeyAzObjectById @p
                                        if($mynetwork){
                                            [void]$networks.Add($mynetwork)
                                        }
                                    }
                                }
                            }
                            else{
                                Write-Warning ("Unable to get Network information from {0}" -f $newVmObject.Id)
                            }
                        }
                        $newVmObject.networking = $networks
                    }
                    #return object
                    return $newVmObject
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}