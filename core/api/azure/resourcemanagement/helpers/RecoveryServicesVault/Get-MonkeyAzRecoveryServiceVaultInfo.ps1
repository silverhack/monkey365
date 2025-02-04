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

Function Get-MonkeyAzRecoveryServiceVaultInfo {
    <#
        .SYNOPSIS
		Get Recovery Services Vault metadata from Azure

        .DESCRIPTION
		Get Recovery Services Vault metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRecoveryServiceVaultInfo
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
        [String]$APIVersion = "2023-02-01"
    )
    Begin{
        #Get Azure RSV Config
		$VaultConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureVault" } | Select-Object -ExpandProperty resource
    }
    Process{
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Recovery Services Vault");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureRSVInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $ars = Get-MonkeyAzObjectById @p
            if($null -ne $ars){
                $rsVaultObject = $ars | New-MonkeyRecoveryServicesVaultObject
                #Get Locks
                $rsVaultObject.locks = $rsVaultObject | Get-MonkeyAzLockInfo
                #Get Storage config
                $rsVaultObject.storageConfig = $rsVaultObject | Get-MonkeyAzRecoveryServicesVaultStorageConfig
                #Get backup policies
                $rsVaultObject.backupPolicies = $rsVaultObject | Get-MonkeyAzRecoveryServicesVaultBackupPolicies
                #Get replication recovery plan
                $rsVaultObject.replicationRecoveryPlan = $rsVaultObject | Get-MonkeyAzRecoveryServicesVaultReplicationRecoveryPlan
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $rsVaultObject.Id;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $rsVaultObject.diagnosticSettings.enabled = $true;
                        $rsVaultObject.diagnosticSettings.name = $diag.name;
                        $rsVaultObject.diagnosticSettings.id = $diag.id;
                        $rsVaultObject.diagnosticSettings.properties = $diag.properties;
                        $rsVaultObject.diagnosticSettings.rawData = $diag;
                    }
                }
                #Return object
                return $rsVaultObject
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
