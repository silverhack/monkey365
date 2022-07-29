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


Function Get-MonkeyEXOUser{
    <#
        .SYNOPSIS
		Plugin to get information about users in Exchange Online

        .DESCRIPTION
		Plugin to get information about users in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOUser
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
        #Getting environment
        $Environment = $O365Object.Environment
        #Get EXO authentication
        $exo_auth = $O365Object.auth_tokens.ExchangeOnline
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Online users", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('ExoUsersInfo');
        }
        Write-Information @msg
        #Get data
        $param = @{
            Authentication = $exo_auth;
            Environment = $Environment;
            ObjectType = "User";
            extraParameters = "PropertySet=All";
        }
        $exo_users = Get-PSExoAdminApiObject @param
    }
    End{
        if($exo_users){
            $exo_users.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.Users')
            [pscustomobject]$obj = @{
                Data = $exo_users
            }
            $returnData.o365_exo_users = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online users", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoUsersEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
