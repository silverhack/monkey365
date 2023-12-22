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

Function Get-MonkeyAzKeyVault {
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
            File Name	: Get-MonkeyAzKeyVault
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
        [String]$APIVersion = "2021-10-01"
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
            if($null -ne $vaultObject){
                #Check for purge protection
                if($null -eq $vaultObject.Properties.PsObject.Properties.Item('enablePurgeProtection')){
                    $vaultObject.Properties | Add-Member -type NoteProperty -name enablePurgeProtection -value $false -Force
                }
                #Get Network properties
			    if (-not $vaultObject.Properties.networkAcls) {
				    $vaultObject | Add-Member -Type NoteProperty -Name allowAccessFromAllNetworks -Value $true
			    }
			    elseif ($vaultObject.Properties.networkAcls.bypass -eq "AzureServices" -and $vaultObject.Properties.networkAcls.defaultAction -eq "Allow") {
				    $vaultObject | Add-Member -Type NoteProperty -Name allowAccessFromAllNetworks -Value $true
			    }
			    else {
				    $vaultObject | Add-Member -Type NoteProperty -Name allowAccessFromAllNetworks -Value $false
			    }
                $vaultObject = New-MonkeyVaultObject -KeyVault $vaultObject
                #Get keys
                $p = @{
                    KeyVault = $vaultObject;
                    ObjectType = 'keys';
                    GetProperties = $True;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $keys = Get-MonkeyAzKeyVaultObject @p
                if($keys){
                    $vaultObject.objects.keys = $keys;
                }
                #Get secrets
                $p = @{
                    KeyVault = $vaultObject;
                    ObjectType = 'secrets';
                    GetProperties = $True;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $secrets = Get-MonkeyAzKeyVaultObject @p
                if($secrets){
                    $vaultObject.objects.secrets = $secrets;
                }
                #Get certificates
                $p = @{
                    KeyVault = $vaultObject;
                    ObjectType = 'certificates';
                    GetProperties = $True;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $certificates = Get-MonkeyAzKeyVaultObject @p
                if($certificates){
                    $vaultObject.objects.certificates = $certificates;
                }
                #Get Diagnostic settings
                $p = @{
                    Id = $vaultObject.Id;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                if($diag){
                    $vaultObject.diagnosticSettings.enabled = $true;
                    $vaultObject.diagnosticSettings.name = $diag.name;
                    $vaultObject.diagnosticSettings.id = $diag.id;
                    $vaultObject.diagnosticSettings.properties = $diag.properties;
                    $vaultObject.diagnosticSettings.rawData = $diag;
                }
                #Get locks
                $vaultObject.locks = $vaultObject | Get-MonkeyAzLockInfo
                #return vault object
                return $vaultObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}