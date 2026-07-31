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

Function Update-MonkeyAzNetworkForVMScaleSet {
    <#
        .SYNOPSIS
		Update network configuration for an Virtual Machine Scale set object

        .DESCRIPTION
		Update network configuration for an Virtual Machine Scale set object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-MonkeyAzNetworkForVMScaleSet
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
        [String]$APIVersion = "2026-03-01"
    )
    Process{
        try{
            #Set arrays
            $nsgs = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
            $vnetworks = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
            $subnets = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
            #Get Subnet, network interface and Virtual network
            #Get network configuration
            $networkIfaceConfiguration = $InputObject.GetPropertyByPath('properties.virtualMachineProfile.networkProfile.networkInterfaceConfigurations');
            ForEach($ifaceConf in @($networkIfaceConfiguration).Where({$null -ne $_})){
                $nsgId = $ifaceConf.GetPropertyByPath('properties.networkSecurityGroup.id');
                If($null -ne $nsgId){
                    $nsgObject = $O365Object.all_resources.Where({$_.id -eq $nsgId});
                    ForEach($nsg in @($nsgObject).Where({$null -ne $_})){
                        $nsgobj = $nsg | Get-MonkeyAzNetworkSecurityGroupInfo
                        If($nsgobj){
                            [void]$nsgs.Add($nsgobj);
                        }
                    }
                }
                #Get virtual networks and subnet
                $ipConfigurations = $ifaceConf.GetPropertyByPath('properties.ipConfigurations')
                ForEach($ipConf in @($ipConfigurations).Where({$null -ne $_})){
                    $subnetId = $ipConf.GetPropertyByPath('properties.subnet.id');
                    $vnetworkId = $null
                    If($subnetId){
                        $subnet = $subnetId | Get-MonkeyAzSubnetById
                        If($subnet){
                            [void]$subnets.Add($subnet);
                        }
                        #Get virtual network Id
                        $vnetId = $subnetId.Remove($subnetId.LastIndexOf('/subnets/'));
                        If($vnetId){
                            $vnetworkObj = $O365Object.all_resources.Where({$_.id -eq $vnetId});
                            If($vnetworkObj){
                                $vnetworkObject = $vnetworkObj | Get-MonkeyAzVirtualNetworkInfo
                                If($vnetworkObject){
                                    [void]$vnetworks.Add($vnetworkObject);
                                }
                            }
                        }
                    }
                }
            }
            #Update object
            $InputObject.networking.virtualNetworks = $vnetworks;
            $InputObject.networking.networkSecurityGroups = $nsgs;
            $InputObject.networking.subnets = $subnets;
            #return object
            return $InputObject
        }
        catch{
            Write-Verbose $_
        }
    }
}
