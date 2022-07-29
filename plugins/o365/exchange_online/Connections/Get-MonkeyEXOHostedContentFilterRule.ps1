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


Function Get-MonkeyEXOHostedContentFilterRule{
    <#
        .SYNOPSIS
		Plugin to get information about hosted content filter rules in Exchange Online

        .DESCRIPTION
		Plugin to get information about hosted content filter rules in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOHostedContentFilterRule
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
        $hosted_content_rule = $null
        #Check if already connected to Exchange Online
        $exo_session = Test-EXOConnection
    }
    Process{
        if($exo_session){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Online Hosted content filter rule", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('ExoHostedContentInfo');
            }
            Write-Information @msg
            $hosted_content_rule = Get-ExoMonkeyHostedContentFilterRule
        }
    }
    End{
        if($null -ne $hosted_content_rule){
            $hosted_content_rule.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.hosted_content_filter.rules')
            [pscustomobject]$obj = @{
                Data = $hosted_content_rule
            }
            $returnData.o365_exo_content_filter_rule = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online Hosted content filter rule", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoHostedContentEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
