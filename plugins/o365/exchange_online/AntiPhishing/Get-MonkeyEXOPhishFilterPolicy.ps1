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


Function Get-MonkeyEXOPhishFilterPolicy{
    <#
        .SYNOPSIS
		Plugin to get information about Phish filter policy in Exchange Online

        .DESCRIPTION
		Plugin to get information about Phish filter policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOPhishFilterPolicy
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
        $exo_phish_filter_policy = $null
        #Check if already connected to Exchange Online
        $exo_session = Test-EXOConnection
    }
    Process{
        if($exo_session){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Phish filter policy", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('ExoPhishFilterPolicyInfo');
            }
            Write-Information @msg
            #https://docs.microsoft.com/en-us/powershell/module/exchange/get-phishfilterpolicy?view=exchange-ps
            # TODO This cmdlet is in the process of being deprecated
            $exo_phish_filter_policy = Get-ExoMonkeyPhishFilterPolicy
        }
    }
    End{
        if($null -ne $exo_phish_filter_policy){
            $exo_phish_filter_policy.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.PhishFilterPolicy')
            [pscustomobject]$obj = @{
                Data = $exo_phish_filter_policy
            }
            $returnData.o365_exo_phish_filter_policy = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Phish filter policy", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoPhishFilterResponse');
            }
            Write-Warning @msg
        }
    }
}
