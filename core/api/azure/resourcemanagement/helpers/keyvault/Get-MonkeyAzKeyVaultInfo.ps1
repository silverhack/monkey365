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

Function Get-MonkeyAzKeyVaultInfo {
    <#
        .SYNOPSIS
		Get Azure keyvault

        .DESCRIPTION
		Get Azure keyvault

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzKeyVaultInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[cmdletbinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Key Vault Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2026-02-01"
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
			    Id = $InputObject.id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $_obj = Get-MonkeyAzObjectById @p
            If($null -ne $_obj){
                $vaultObject = $_obj | New-MonkeyVaultObject
                #Get metadata for keys
                $p = @{
                    KeyVault = $vaultObject;
                    ObjectType = 'keys';
                    RotationPolicy = $true
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $vaultObject.objects.keys = Get-MonkeyAzKeyVaultObject @p
                #Get metadata for secrets
                $p = @{
                    KeyVault = $vaultObject;
                    ObjectType = 'secrets';
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $vaultObject.objects.secrets = Get-MonkeyAzKeyVaultObject @p
                #Get metadata for certificates
                $p = @{
                    KeyVault = $vaultObject;
                    ObjectType = 'certificates';
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $vaultObject.objects.certificates = Get-MonkeyAzKeyVaultObject @p
                #Get Diagnostic settings
                $p = @{
                    Id = $vaultObject.Id;
                    ApiVersion = $diag_settings_api_Version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                If($diag){
                    $vaultObject.diagnosticSettings.enabled = $true;
                    $vaultObject.diagnosticSettings.name = $diag.name;
                    $vaultObject.diagnosticSettings.id = $diag.id;
                    $vaultObject.diagnosticSettings.properties = $diag.properties;
                    $vaultObject.diagnosticSettings.rawData = $diag;
                }
                #Get locks
                $vaultObject.locks = $vaultObject | Get-MonkeyAzLockInfo
                # Get Private Endpoint connections
                $p = @{
					InputObject = $vaultObject;
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
		        $vaultObject.networking.privateEndpointConnections = Get-MonkeyAzGenericPrivateEndpoint @p
                return $vaultObject
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}
