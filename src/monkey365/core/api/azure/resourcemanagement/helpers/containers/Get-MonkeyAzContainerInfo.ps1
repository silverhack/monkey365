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

Function Get-MonkeyAzContainerInfo {
    <#
        .SYNOPSIS
		Get container instance metadata from Azure

        .DESCRIPTION
		Get container instance metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzContainerInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-09-01"
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
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $containerObj = Get-MonkeyAzObjectById @p
            $newContainer = $containerObj | New-MonkeyContainerObject
            #Get virtualNetworkId
            If($null -ne $newContainer.networking.subnetIds){
                $subnetId = $newContainer.networking.subnetIds | Select-Object -First 1 -ErrorAction Ignore
                If($null -ne $subnetId){
                    $newContainer.networking.virtualNetworkId = $subnetId.id.Remove($subnetId.id.LastIndexOf('/subnets/'));   
                }
            }
            #Get Containers
            $p = @{
				InputObject = $newContainer;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
			}
            $newContainer.containers = Get-MonkeyAzContainerProperty @p
            #Get locks
            $newContainer.locks = $newContainer | Get-MonkeyAzLockInfo
            #Get managed identity RBAC
            $newContainer.identityRbac = $newContainer | Get-MonkeyAzRBACForManagedIdentity
            #Get diagnostic settings
            If($InputObject.supportsDiagnosticSettings -eq $True){
                $p = @{
		            Id = $newContainer.Id;
                    ApiVersion = $diag_settings_api_Version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $diag = Get-MonkeyAzDiagnosticSettingsById @p
                if($diag){
                    #Add to object
                    $newContainer.diagnosticSettings.enabled = $true;
                    $newContainer.diagnosticSettings.name = $diag.name;
                    $newContainer.diagnosticSettings.id = $diag.id;
                    $newContainer.diagnosticSettings.properties = $diag.properties;
                    $newContainer.diagnosticSettings.rawData = $diag;
                }
            }
            #return object
            return $newContainer
        }
        catch{
            Write-Verbose $_
        }
    }
}
