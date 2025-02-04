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

	[cmdletbinding(DefaultParameterSetName='KeyVault')]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = 'Id')]
        [String]$Id,

        [Parameter(Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = 'KeyVault')]
        [Object]$KeyVault,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2024-11-01"
    )
    Process{
        try{
            $vaultObject = $null;
            if($PSCmdlet.ParameterSetName -eq 'Id'){
                $p = @{
			        Id = $Id;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $vaultObject = Get-MonkeyAzObjectById @p
            }
            else{
                $p = @{
			        Id = $KeyVault.Id;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $vaultObject = Get-MonkeyAzObjectById @p
            }
            If($null -ne $vaultObject){
                $vaultObj = $vaultObject | New-MonkeyVaultObject
                If($null -ne $vaultObj){
                    #Get Network properties
	                If ($null -ne $vaultObj.properties.PsObject.Properties.Item('publicNetworkAccess') -and  $vaultObj.properties.publicNetworkAccess.ToLower() -eq "enabled") {
                        $vaultObj.allowAccessFromAllNetworks = $true
	                }
                    Elseif ($null -ne $vaultObj.networkAcls -and $vaultObj.networkAcls.bypass -eq "AzureServices" -and $vaultObj.networkAcls.defaultAction -eq "Allow") {
	                    $vaultObj.allowAccessFromAllNetworks = $true
	                }
                    Else{
                        $vaultObj.allowAccessFromAllNetworks = $false
                    }
                    #Get keys
                    $p = @{
                        KeyVault = $vaultObj;
                        ObjectType = 'keys';
                        RotationPolicy = $true
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $keys = Get-MonkeyAzKeyVaultObject @p
                    If($keys){
                        $vaultObj.objects.keys = $keys;
                    }
                    #Get secrets
                    $p = @{
                        KeyVault = $vaultObj;
                        ObjectType = 'secrets';
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $secrets = Get-MonkeyAzKeyVaultObject @p
                    If($secrets){
                        $vaultObj.objects.secrets = $secrets;
                    }
                    #Get certificates
                    $p = @{
                        KeyVault = $vaultObj;
                        ObjectType = 'certificates';
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $certificates = Get-MonkeyAzKeyVaultObject @p
                    If($certificates){
                        $vaultObj.objects.certificates = $certificates;
                    }
                    #Get Diagnostic settings
                    $p = @{
                        Id = $vaultObj.Id;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    If($diag){
                        $vaultObj.diagnosticSettings.enabled = $true;
                        $vaultObj.diagnosticSettings.name = $diag.name;
                        $vaultObj.diagnosticSettings.id = $diag.id;
                        $vaultObj.diagnosticSettings.properties = $diag.properties;
                        $vaultObj.diagnosticSettings.rawData = $diag;
                    }
                    #Get locks
                    $vaultObj.locks = $vaultObj | Get-MonkeyAzLockInfo
                    <#
                    #Get key rotation policy
                    If($null -ne $vaultObj.objects.keys){
                        ForEach($key in @($vaultObj.objects.keys)){
                            $rotationPolicy = Get-MonkeyAzKeyVaultKeyRotationPolicy -key $key
                            If($rotationPolicy){
                                $key | Add-Member -Type NoteProperty -Name rotationPolicy -Value $rotationPolicy
                            }
                            Else{
                                $key | Add-Member -Type NoteProperty -Name rotationPolicy -Value $null
                            }
                        }
                    }
                    #>
                    #return object
                    return $vaultObj
                }
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}

