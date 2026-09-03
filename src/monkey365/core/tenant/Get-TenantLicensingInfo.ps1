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
# See the License for the specIfic language governing permissions and
# limitations under the License.

Function Get-TenantLicensingInfo{
    <#
        .SYNOPSIS
        Get licensing info from current tenant

        .DESCRIPTION
        Get licensing info from current tenant

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-TenantLicensingInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="SKU licenses")]
        [Object]$SKU
    )
    Begin{
        #Set PsCustomObject
        $licensingInfo= [PsCustomObject]@{
            EntraIDP1 = $null;
            EntraIDP2 = $null;
            ATPEnabled = $null;
            E5 = $null;
            E3 = $null;
            ActiveLicenses = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
            DisabledLicenses = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        }
    }
    Process{
        Try{
            $allLicenses = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
            #Check if Entra ID P1 is enabled
            $licensingInfo.EntraIDP1 = Find-M365License -SKU $SKU -EntraIDP1
            #Check if Entra ID P2 is enabled
            $licensingInfo.EntraIDP2 = Find-M365License -SKU $SKU -EntraIDP2
            #Check if ATP is enabled
            $licensingInfo.ATPEnabled = Find-M365License -SKU $SKU -AdvancedThreatProtection
            #Check if E3 license is enabled
            $licensingInfo.E3 = Find-M365License -SKU $SKU -E3License
            ForEach($license in @($licensingInfo.E3).Where({$null -ne $_}).GetEnumerator()){
                [void]$allLicenses.Add($license);
            }
            #Check if E5 license is enabled
            $licensingInfo.E5 = Find-M365License -SKU $SKU -E5License
            ForEach($license in @($licensingInfo.E5).Where({$null -ne $_}).GetEnumerator()){
                [void]$allLicenses.Add($license);
            }
            If(@($licensingInfo.E3).Count -eq 0 -and @($licensingInfo.E5).Count -eq 0){
                #Check if non E3/E5 license is enabled
                $genericLicense = Find-M365License -SKU $SKU -GenericLicense
                If($null -ne $genericLicense){
                    [void]$allLicenses.Add($genericLicense);
                }
            }
            #Find Active license
            $activeLicenses = $allLicenses.Where({$_.capabilityStatus -eq "Enabled"});
            If($activeLicenses.Count -gt 0){
                ForEach($activeLicense in $activeLicenses){
                    [void]$licensingInfo.ActiveLicenses.Add($activeLicense);        
                }
            }
            #Find suspended licenses
            $suspendedLicenses = $allLicenses.Where({$_.capabilityStatus -eq "Suspended"});
            If($suspendedLicenses.Count -gt 0){
                ForEach($suspendedLicense in $suspendedLicenses){
                    [void]$licensingInfo.SuspendedLicenses.Add($suspendedLicense);        
                }
            }
        }
        Catch{
            $msg = @{
                MessageData = $message.O365TenantInfoError;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                Tags = @('EIDTenantError');
            }
            Write-Warning @msg
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                Tags = @('EIDTenantError');
            }
            Write-Debug @msg
        }
    }
    End{
        return $licensingInfo
    }
}

