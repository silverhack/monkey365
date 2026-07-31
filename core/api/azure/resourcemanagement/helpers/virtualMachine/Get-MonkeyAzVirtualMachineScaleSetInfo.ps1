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

Function Get-MonkeyAzVirtualMachineScaleSetInfo {
    <#
        .SYNOPSIS
		Get Azure Virtual Machine scale set info

        .DESCRIPTION
		Get Azure Virtual Machine scale set info

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVirtualMachineScaleSetInfo
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
        [String]$APIVersion = "2026-03-01"
    )
    Begin{
        $config = @($O365Object.internal_config.resourceManager).Where({$_.Name -eq "DiagnosticSettings"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        If($config){
            $diag_settings_api_Version = $config.api_version;
        }
        Else{
            #Fallback
            $diag_settings_api_Version = "2021-05-01-preview"
        }
    }
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
		    $scaleSet = Get-MonkeyAzObjectById @p
            If($scaleSet){
                $scaleSetObject = $scaleSet | New-MonkeyVmScaleSetObject
                #Update network information
                $p = @{
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
                $scaleSetObject = $scaleSetObject | Update-MonkeyAzNetworkForVMScaleSet
                #Get instances
                $p = @{
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
                $scaleSetObject.instances = $scaleSetObject | Get-MonkeyAzVMScaleSetInstance
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $scaleSetObject.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    If($diag){
                        #Add to object
                        $scaleSetObject.diagnosticSettings.enabled = $true;
                        $scaleSetObject.diagnosticSettings.name = $diag.name;
                        $scaleSetObject.diagnosticSettings.id = $diag.id;
                        $scaleSetObject.diagnosticSettings.properties = $diag.properties;
                        $scaleSetObject.diagnosticSettings.rawData = $diag;
                    }
                }
                #######Get update config########
                If($null -ne ($scaleSetObject.properties | Select-Object -ExpandProperty virtualMachineProfile -ErrorAction Ignore)){
                    If($scaleSetObject.properties.virtualMachineProfile.storageProfile.osDisk.osType -eq 'windows'){
                        $enableAutomaticUpdates = $scaleSetObject.properties.virtualMachineProfile.osProfile.windowsConfiguration.PsObject.Properties.Item('enableAutomaticUpdates');
                        If($null -eq $enableAutomaticUpdates){
                            $scaleSetObject.automaticUpdates.enabled = $false;
                        }
                        Else{
                            $scaleSetObject.automaticUpdates.enabled = $scaleSetObject.properties.virtualMachineProfile.osProfile.windowsConfiguration.enableAutomaticUpdates;
                        }
                    }
                    Else{
                        If($null -eq $scaleSetObject.properties.virtualMachineProfile.osProfile.linuxConfiguration.PsObject.Properties.Item('enableAutomaticUpdates')){
                            $scaleSetObject.automaticUpdates.enabled = $false;
                        }
                        Else{
                            $patchMode = $scaleSetObject.properties.virtualMachineProfile.osProfile.linuxConfiguration.patchSettings.patchMode
                            If($patchMode -eq 'Manual'){
                                $scaleSetObject.automaticUpdates.enabled = $false
                            }
                            Else{
                                $scaleSetObject.automaticUpdates.enabled = $True
                            }
                        }
                    }
                    $scaleSetObject.automaticUpdates.rawObject = $scaleSetObject.properties.virtualMachineProfile.osProfile;
                }
                #Get locks
                $scaleSetObject.locks = $scaleSetObject | Get-MonkeyAzLockInfo
                #return object
                return $scaleSetObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
