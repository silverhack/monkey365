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

Function Get-MonkeyAzVMNicInfo {
    <#
        .SYNOPSIS
		Get Azure VM OS NIC info

        .DESCRIPTION
		Get Azure VM OS NIC info

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVMNicInfo
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
		$AzureNICConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureVMNetworkInterface" } | Select-Object -ExpandProperty resource
    }
    Process{
        try{
            If ($InputObject.properties.networkProfile.networkInterfaces.Count -gt 0) {
                Foreach($interface in $InputObject.properties.networkProfile.networkInterfaces){
                    $p = @{
	                    Id = $interface.id;
                        ApiVersion = $AzureNICConfig.api_version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $nic = Get-MonkeyAzObjectById @p
                    If($nic){
                        $localNic = $InputObject.newLocalNic()
                        $localNic.name = $nic.name;
                        $localNic.localIpAddress = $nic.properties.ipConfigurations.properties.privateIPAddress;
                        $localNic.macAddress = $nic.properties.macAddress;
                        $localNic.ipForwardingEnabled = $nic.properties.enableIPForwarding;
                        $localNic.rawObject = $nic;
                        #Append to localNic
                        $InputObject.localNic.Add($localNic);
                        #Check public IP
                        $publicNic = $nic.properties.ipConfigurations.Where({$null -ne $_.properties.psObject.Properties.Item('publicIpAddress')})
                        If($publicNic.Count -gt 0){
                            Foreach($public in $publicNic){
                                $p = @{
	                                Id = $public.properties.publicIPAddress.id;
                                    ApiVersion = $AzureNICConfig.api_version;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                    InformationAction = $O365Object.InformationAction;
                                }
                                $publicIp = Get-MonkeyAzObjectById @p
                                if($publicIp){
                                    $newNic = $InputObject.newPublicNic()
                                    $newNic.publicIpAddress = $publicIp.properties.ipAddress;
                                    $newNic.publicIPAllocationMethod = $publicIp.Properties.publicIPAllocationMethod;
                                    $newNic.rawObject = $publicIp;
                                    #Add to publicNic
                                    $InputObject.publicNic.Add($newNic);
                                }
                            }
                        }
                    }
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
