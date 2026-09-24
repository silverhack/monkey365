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

Function Get-MonkeyAzKubernetesInfo {
    <#
        .SYNOPSIS
		Get kubernetes info from Azure

        .DESCRIPTION
		Get kubernetes info from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzKubernetesInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Kubernetes Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-06-01"
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
		    $myKubeobject = Get-MonkeyAzObjectById @p
            if($myKubeobject){
                $newKubeObject = $myKubeobject | New-MonkeyKubeObject
                if($newKubeObject){
                    #Get Diagnostic state
                    $p = @{
						KubernetesObject = $newKubeObject;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
                    $newKubeObject.diagnosticsState = Get-MonkeyAzKubernetesDiagnosticState @p
                    #Get agent pool
                    $p = @{
						KubernetesObject = $newKubeObject;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$agentPools = Get-MonkeyAzKubernetesAgentPool @p
                    if($agentPools){
                        $newKubeObject.agentPools = $agentPools;
                    }
                    #######Get upgrade profile########
                    $p = @{
						KubernetesObject = $newKubeObject;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
                    $newKubeObject.upgradeProfile = Get-MonkeyAzKubernetesUpgradeProfile @p
                    #######Get extensions########
                    $p = @{
						KubernetesObject = $newKubeObject;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$newKubeObject.extensions = Get-MonkeyAzKubernetesExtension @p
                    #Get locks
                    $newKubeObject.locks = $newKubeObject | Get-MonkeyAzLockInfo
                    #Get diagnostic settings
                    If($InputObject.supportsDiagnosticSettings -eq $True){
                        $p = @{
                            Id = $InputObject.Id;
                            ApiVersion = $diag_settings_api_Version;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
                        }
                        $diag = Get-MonkeyAzDiagnosticSettingsById @p
                        if($diag){
                            #Add to object
                            $newKubeObject.diagnosticSettings.enabled = $true;
                            $newKubeObject.diagnosticSettings.name = $diag.name;
                            $newKubeObject.diagnosticSettings.id = $diag.id;
                            $newKubeObject.diagnosticSettings.properties = $diag.properties;
                            $newKubeObject.diagnosticSettings.rawData = $diag;
                        }
                    }
                    #return object
                    return $newKubeObject
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
