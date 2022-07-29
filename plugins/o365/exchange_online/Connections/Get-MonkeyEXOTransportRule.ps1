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


Function Get-MonkeyEXOTransportRule{
    <#
        .SYNOPSIS
		Plugin to get information about transport rules in Exchange Online

        .DESCRIPTION
		Plugin to get information about transport rules in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOTransportRule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
        [String]$pluginId
    )
    Begin{
        $exo_transport_rules = $null
        #Check if already connected to Exchange Online
        $exo_session = Test-EXOConnection
        #Get Tenant info
        $tenant_info = $O365Object.Tenant
        #Get available domains for organisation
        $org_domains = $tenant_info.Domains | Select-Object -ExpandProperty id
    }
    Process{
        if($exo_session){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Online transport rules", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('ExoTransportRulesInfo');
            }
            Write-Information @msg
            $exo_transport_rules = Get-ExoMonkeyTransportRule
            if($null -ne $exo_transport_rules){
                foreach($transport_rule in $exo_transport_rules){
                    #Check if own domain is already whitelisted in SenderDomain
                    $params = @{
                        ReferenceObject = $org_domains;
                        DifferenceObject = $transport_rule.SenderDomainIs;
                        IncludeEqual= $true;
                        ExcludeDifferent = $true;
                    }
                    $org_whitelisted_InsenderDomain = Compare-Object @params
                    #Check if own domain is already whitelisted in FromAddressContainsWords
                    $params = @{
                        ReferenceObject = $org_domains;
                        DifferenceObject = $transport_rule.FromAddressContainsWords;
                        IncludeEqual= $true;
                        ExcludeDifferent = $true;
                    }
                    $org_whitelisted_InFromAddress = Compare-Object @params
                    if($org_whitelisted_InsenderDomain -or $org_whitelisted_InFromAddress){
                        $transport_rule | Add-Member -type NoteProperty -name IsCompanyWhiteListed -value $true
                    }
                    else{
                        $transport_rule | Add-Member -type NoteProperty -name IsCompanyWhiteListed -value $false
                    }
                }
            }
            if($null -eq $exo_transport_rules){
                $exo_transport_rules = @{
                    isEnabled = $false
                }
            }
        }
    }
    End{
        if($null -ne $exo_transport_rules){
            $exo_transport_rules.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.TransportRules')
            [pscustomobject]$obj = @{
                Data = $exo_transport_rules
            }
            $returnData.o365_exo_transport_rules = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online transport rules", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoTransportRulesResponse');
            }
            Write-Warning @msg
        }
    }
}
