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


Function Get-MonkeyEXOHostedConnectionFilterPolicy{
    <#
        .SYNOPSIS
		Plugin to get information about hosted connection filter policy in Exchange Online

        .DESCRIPTION
		Plugin to get information about hosted connection filter policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOHostedConnectionFilterPolicy
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
        $hosted_conn_filter = $null
        #Check if already connected to Exchange Online
        $exo_session = Test-EXOConnection
    }
    Process{
        if($exo_session){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Online Hosted connection filter policy", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('ExoHostedConnectionInfo');
            }
            Write-Information @msg
            $hosted_conn_filter = Get-ExoMonkeyHostedConnectionFilterPolicy
        }
    }
    End{
        if($null -ne $hosted_conn_filter){
            $hosted_conn_filter.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.HostedConnectionFilterPolicy')
            [pscustomobject]$obj = @{
                Data = $hosted_conn_filter
            }
            $returnData.o365_exo_connection_policy = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online hosted connection filter policy", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoHostedConnectionEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
