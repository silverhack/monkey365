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

Function Get-MonkeyAzSQlVirtualMachineInfo {
    <#
        .SYNOPSIS
		Get SQL managed instance resource from Azure

        .DESCRIPTION
		Get SQL server from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSQlManagedInstanceServer
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-10-01"
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
        $vmConfig = $O365Object.internal_config.ResourceManager.Where({$_.Name -eq "azureVm"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        If($vmConfig){
            $vm_api_version = $vmConfig.api_version;
        }
        Else{
            #Fallback
            $vm_api_version = "2025-04-01"
        }
    }
    Process{
        Try{
            $p = @{
	            Id = $InputObject.Id;
                Expand = '*'
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
		    $dbServer = Get-MonkeyAzObjectById @p
            If($dbServer){
                $new_dbServer = $dbServer | New-MonkeySQLVMObject
                #Get extensions
                $p = @{
					Id = $new_dbServer.properties.virtualMachineResourceId;
                    Detailed = $True;
                    APIVersion = $vm_api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$new_dbServer.extensions = Get-MonkeyAzVMExtension @p
                #Get locks
                $new_dbServer.locks = $new_dbServer | Get-MonkeyAzLockInfo
                #Get VM Info
                $vmObj = $O365Object.all_resources.Where({$_.id -eq $new_dbServer.properties.virtualMachineResourceId})
                If($vmObj.Count -gt 0){
                    $vmInfo = $vmObj | Get-MonkeyAzVirtualMachineInfo
                    $new_dbServer.updates = $vmInfo | Select-Object -ExpandProperty updates -ErrorAction Ignore
                    $new_dbServer.latestPatchResults = $vmInfo | Select-Object -ExpandProperty latestPatchResults -ErrorAction Ignore
                    $new_dbServer.automaticUpdates = $vmInfo | Select-Object -ExpandProperty automaticUpdates -ErrorAction Ignore
                }
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $new_dbServer.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $new_dbServer.diagnosticSettings.enabled = $true;
                        $new_dbServer.diagnosticSettings.name = $diag.name;
                        $new_dbServer.diagnosticSettings.id = $diag.id;
                        $new_dbServer.diagnosticSettings.properties = $diag.properties;
                        $new_dbServer.diagnosticSettings.rawData = $diag;
                    }
                }
                return $new_dbServer
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}
