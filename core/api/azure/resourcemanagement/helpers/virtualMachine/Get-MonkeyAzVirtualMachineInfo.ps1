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

Function Get-MonkeyAzVirtualMachineInfo {
    <#
        .SYNOPSIS
		Get virtual machine instance metadata from Azure

        .DESCRIPTION
		Get virtual machine instance metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVirtualMachineInfo
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
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Virtual machine");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureVMInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                Expand = 'instanceView';
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $vm = Get-MonkeyAzObjectById @p
            if($null -ne $vm){
                $vmObject = $vm | New-MonkeyVMObject
                #Check for antimalware
                $vmObject.defaultExtensions.isAVAgentInstalled = $vmObject | Get-MonkeyAzVMAVInfo
                #Check for legacy monitoring agent
                $vmObject.defaultExtensions.isVMLegacyMonitorAgentInstalled = $vmObject | Get-MonkeyAzVMOMSInfo -Legacy
                #Check for monitoring agent
                $vmObject.defaultExtensions.isVMMonitorAgentInstalled = $vmObject | Get-MonkeyAzVMOMSInfo
                #Check for restore points
                $vmObject.backup.restorePoint = $vmObject | Get-MonkeyAzVMRestorePoint
                #Check OS Disk
                $vmObject | Get-MonkeyAzVMOSDiskInfo
                #Get Data disks
                $vmObject | Get-MonkeyAzVMOSDataDiskInfo
                #Get NIC info
                $vmObject | Get-MonkeyAzVMNicInfo
                #Get Security Profile info
                $vmObject | Get-MonkeyAzVMSecurityProfileInfo
                #Get Locks
                $vmObject.locks = $vmObject | Get-MonkeyAzLockInfo
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $vmObject.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $vmObject.diagnosticSettings.enabled = $true;
                        $vmObject.diagnosticSettings.name = $diag.name;
                        $vmObject.diagnosticSettings.id = $diag.id;
                        $vmObject.diagnosticSettings.properties = $diag.properties;
                        $vmObject.diagnosticSettings.rawData = $diag;
                    }
                }
                #Get Missing patches
                $p = @{
		            InputObject = $vmObject;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $vmObject.updates = Get-MonkeyVMMissingKb @p
                #Get latest assessment result
                $p = @{
		            InputObject = $vmObject;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $vmObject.latestPatchResults = Get-MonkeyVMPatchAssessmentResult @p
                #Check for updates configuration
                If($vmObject.properties.storageProfile.osDisk.osType.ToLower() -eq 'windows'){
                    $vmObject.automaticUpdates.enabled = $vmObject.properties.osProfile.windowsConfiguration | Select-Object -ExpandProperty enableAutomaticUpdates -ErrorAction Ignore
                    $vmObject.automaticUpdates.patchMode = $vmObject.properties.osProfile.windowsConfiguration.patchSettings.patchMode;
                    $vmObject.automaticUpdates.automaticByPlatformSettings = $vmObject.properties.osProfile.windowsConfiguration.patchSettings.automaticByPlatformSettings;
                    $vmObject.automaticUpdates.assessmentMode = $vmObject.properties.osProfile.windowsConfiguration.patchSettings.assessmentMode;
                    $vmObject.automaticUpdates.enableHotpatching = $vmObject.properties.osProfile.windowsConfiguration.patchSettings.enableHotpatching;
                    $vmObject.automaticUpdates.rawObject = $vmObject.properties.osProfile;
                }
                If($vmObject.properties.storageProfile.osDisk.osType.ToLower() -eq 'linux'){
                    $vmObject.automaticUpdates.patchMode = $vmObject.properties.osProfile.linuxConfiguration.patchSettings.patchMode;
                    $vmObject.automaticUpdates.automaticByPlatformSettings = $vmObject.properties.osProfile.linuxConfiguration.patchSettings.automaticByPlatformSettings;
                    $vmObject.automaticUpdates.assessmentMode = $vmObject.properties.osProfile.linuxConfiguration.patchSettings.assessmentMode;
                    $vmObject.automaticUpdates.rawObject = $vmObject.properties.osProfile;
                }
                #Get configuration management
                $p = @{
		            InputObject = $vmObject;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $_confManagement = Get-MonkeyVMConfigurationManagement @p
                $configurationManagement = [System.Collections.Generic.List[System.Object]]::new()
                ForEach($cnf in $_confManagement){
                    [void]$configurationManagement.Add($cnf);
                }
                $vmObject.configurationManagement = $configurationManagement;
                #Return object
                return $vmObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
