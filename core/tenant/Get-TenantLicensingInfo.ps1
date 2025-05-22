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
            ProductInfo = [PsCustomObject]@{
                displayName = $null;
                Id = $null;
                capabilityStatus = $null;
                consumedUnits = $null;
                prepaidUnits = $null;
                accountName = $null;
            };
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
            $e3License = Find-M365License -SKU $SKU -E3License
            If($null -ne $e3License){
                [void]$allLicenses.Add($e3License);
            }
            #Check if E5 license is enabled
            $e5License = Find-M365License -SKU $SKU -E5License
            If($null -ne $e5License){
                [void]$allLicenses.Add($e5License);
            }
            If($null -eq $e3License -and $null -eq $e5License){
                #Check if non E3/E5 license is enabled
                $genericLicense = Find-M365License -SKU $SKU -GenericLicense
                If($null -ne $genericLicense){
                    [void]$allLicenses.Add($genericLicense);
                }
            }
            #Find Active license
            $activeLicense = $allLicenses.Where({$_.capabilityStatus -eq "Enabled"});
            If($activeLicense.Count -gt 0){
                $licensingInfo.ProductInfo.displayName = $activeLicense.skuPartNumber
                $licensingInfo.ProductInfo.Id = $activeLicense.skuId
                $licensingInfo.ProductInfo.accountName = $activeLicense.accountName
                $licensingInfo.ProductInfo.capabilityStatus = $activeLicense.capabilityStatus
                $licensingInfo.ProductInfo.prepaidUnits = $activeLicense.prepaidUnits
                $licensingInfo.ProductInfo.consumedUnits = $activeLicense.consumedUnits
            }
            Else{
                $suspendedLicense = $allLicenses.Where({$_.capabilityStatus -eq "Suspended"});
                If($suspendedLicense.Count -gt 0){
                    $licensingInfo.ProductInfo.displayName = $suspendedLicense.skuPartNumber
                    $licensingInfo.ProductInfo.Id = $suspendedLicense.skuId
                    $licensingInfo.ProductInfo.accountName = $suspendedLicense.accountName
                    $licensingInfo.ProductInfo.capabilityStatus = $suspendedLicense.capabilityStatus
                    $licensingInfo.ProductInfo.prepaidUnits = $suspendedLicense.prepaidUnits
                    $licensingInfo.ProductInfo.consumedUnits = $suspendedLicense.consumedUnits
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

