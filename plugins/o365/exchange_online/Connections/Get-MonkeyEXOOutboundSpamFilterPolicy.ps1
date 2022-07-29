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


Function Get-MonkeyEXOOutboundSpamFilterPolicy{
    <#
        .SYNOPSIS
		Plugin to get information about outbound spam filter policy in Exchange Online

        .DESCRIPTION
		Plugin to get information about outbound spam filter policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOOutboundSpamFilterPolicy
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
        $exo_outbound_spam_filter_policy = $null
        #Check if already connected to Exchange Online
        $exo_session = Test-EXOConnection
    }
    Process{
        if($exo_session){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Online hosted outbound spam filter policy", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('ExoOutboundSpamFilterInfo');
            }
            Write-Information @msg
            $exo_outbound_spam_filter_policy = Get-ExoMonkeyHostedOutboundSpamFilterPolicy
        }
    }
    End{
        if($null -ne $exo_outbound_spam_filter_policy){
            $exo_outbound_spam_filter_policy.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.OutboundSpamFilterPolicy')
            [pscustomobject]$obj = @{
                Data = $exo_outbound_spam_filter_policy
            }
            $returnData.o365_exo_hosted_spam_policy = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online hosted outbound spam filter policy", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoOutboundSpamFilterResponse');
            }
            Write-Warning @msg
        }
    }
}
