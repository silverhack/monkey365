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

Function Find-M365License{
    <#
        .SYNOPSIS
        Find M365 license by skuPartNumber, servicePlanId, skuId

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Find-M365License
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="SKU licenses")]
        [Object]$SKU,

        [Parameter(Mandatory=$True, ParameterSetName = 'PartNumber', HelpMessage="Search by skuPartNumber")]
        [String]$PartNumber,

        [Parameter(Mandatory=$True, ParameterSetName = 'PlanId', HelpMessage="Search by servicePlanId")]
        [String]$PlanId,

        [Parameter(Mandatory=$True, ParameterSetName = 'Id', HelpMessage="Search by skuId")]
        [String]$Id,

        [Parameter(Mandatory=$True, ParameterSetName = 'EntraIDP1', HelpMessage="Returns SKU object if Entra ID P1 license is enabled")]
        [Switch]$EntraIDP1,

        [Parameter(Mandatory=$True, ParameterSetName = 'EntraIDP2', HelpMessage="Returns SKU object if Entra ID P2 license is enabled")]
        [Switch]$EntraIDP2,

        [Parameter(Mandatory=$True, ParameterSetName = 'ATPLicense', HelpMessage="Returns SKU object if Advanced Threat Protection license is enabled")]
        [Switch]$AdvancedThreatProtection,

        [Parameter(Mandatory=$True, ParameterSetName = 'E3License', HelpMessage="Returns SKU object if E3 license is enabled")]
        [Switch]$E3License,

        [Parameter(Mandatory=$True, ParameterSetName = 'E5License', HelpMessage="Returns SKU object if E5 license is enabled")]
        [Switch]$E5License,

        [Parameter(Mandatory=$True, ParameterSetName = 'GenericLicense', HelpMessage="Returns SKU object if a non E3/E5 license is returned")]
        [Switch]$GenericLicense,

        [parameter(Mandatory= $True, ParameterSetName = 'Default', HelpMessage= "Search by common name")]
        [ValidateSet("ATP","EntraIDP1","EntraIDP2","E5","E3")]
        [String]$LicenseName
    )
    Begin{
        $ATPLicenses = @(
            "493ff600-6a2b-4db6-ad37-a7d4eb214516", #ATP_ENTERPRISE_GOV
            "f20fedf3-f3c3-43c3-8267-2bfdd51c0939" #ATP_ENTERPRISE
        );
        $AAD_PREMIUM = "41781fb2-bc02-4b7c-bd55-b576c07bb09d"
        $AAD_PREMIUM_P2 = "eec0eb4f-6444-4f95-aba0-50c24d67f998"
        $StreamsE3Licenses = @(
            "2c1ada27-dbaa-46f9-bda6-ecb94445f758", #STREAM_O365_E3_GOV
            "9e700747-8b1d-45e5-ab8d-ef187ceec156" #STREAM_O365_E3
        );
        $SharePointLicenses = @(
            "5dbe027f-2339-4123-9542-606e4d348a72", #SHAREPOINTENTERPRISE
            "153f85dd-d912-4762-af6c-d6e0fb4f6692", #SHAREPOINTENTERPRISE_GOV
            "63038b2c-28d0-45f6-bc36-33062963b498", #SHAREPOINTENTERPRISE_EDU
            "902b47e5-dcb2-4fdc-858b-c63a90a2bdb9", #SHAREPOINTDESKLESS
            "b1aeb897-3a19-46e2-8c27-a609413cf193" #SHAREPOINTDESKLESS_GOV
        );
        If($PSBoundParameters.ContainsKey('SKU') -and $PSBoundParameters['SKU']){
            $SKULicenses = $PSBoundParameters['SKU'];
        }
        ElseIf($null -ne $O365Object.Tenant){
            $SKULicenses = $O365Object.Tenant | Select-Object -ExpandProperty SKU -ErrorAction Ignore
        }
        Else{
            $SKULicenses = $null;
        }
    }
    Process{
        Try{
            If($null -ne $SKULicenses){
                Switch($PSCmdlet.ParameterSetName.ToLower()){
                    'id'{
                        @($SKULicenses).Where({$_.skuId -eq $PSBoundParameters['Id']})
                    }
                    'planid'{
                        @($SKULicenses.servicePlans).Where({$_.servicePlanId -eq $PSBoundParameters['PlanId']})
                    }
                    'partnumber'{
                        @($SKULicenses).Where({$_.skuPartNumber -eq $PSBoundParameters['PartNumber']})
                    }
                    'entraidp1'{
                        @($SKULicenses.servicePlans).Where({$_.servicePlanId -eq "41781fb2-bc02-4b7c-bd55-b576c07bb09d"})
                    }
                    'entraidp2'{
                        @($SKULicenses.servicePlans).Where({$_.servicePlanId -eq "eec0eb4f-6444-4f95-aba0-50c24d67f998"})
                    }
                    'atplicense'{
                        @($SKULicenses.servicePlans).Where({$_.servicePlanId -in $ATPLicenses})
                    }
                    'e3license'{
                        @($SKULicenses).Where({$_.servicePlans.Where({$_.servicePlanId -in $StreamsE3Licenses})})
                    }
                    'e5license'{
                        @($SKULicenses).Where({(`
                            $_.ServicePlans.servicePlanId -contains $AAD_PREMIUM -and `
                             $_.ServicePlans.servicePlanId -contains $AAD_PREMIUM_P2) -and `
                              $_.ServicePlans.servicePlanId.Where({$_ -in $SharePointLicenses})
                        });
                    }
                    'genericlicense'{
                        @($SKULicenses).Where({`
                            $_.ServicePlans.servicePlanId -contains $AAD_PREMIUM -and `
                             $_.ServicePlans.servicePlanId.Where({$_ -in $SharePointLicenses})
                        });
                    }
                }
            }
        }
        Catch{
            $msg = @{
                MessageData = $_;
                functionName = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                Tags = @('M365FindLicenseError');
            }
            Write-Error @msg
        }
    }
}

