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

function Get-MonkeyAADPortalWhatIf {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADPortalWhatIf
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'User', ValueFromPipeline = $True)]
        [Object]$User
    )
    Begin{
        $whatIf = $null
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.AzurePortal
    }
    Process{
        try{
            if($null -ne $O365Object.whatIfConfig){
                $whatIf = $O365Object.whatIfConfig
                #Add userId
                $whatIf.conditions.users.included.userIds = @(('{0}' -f $User.Id))
                $params = @{
                    Authentication = $AADAuth;
                    Query = ("WhatIf/Evaluate");
                    Environment = $Environment;
                    PostData = $whatIf;
                    ContentType = 'application/json';
                    Method = "POST";
                    InformationAction = $O365Object.InformationAction;
			        Verbose = $O365Object.Verbose;
			        Debug = $O365Object.Debug;
                }
                $whatIf = Get-MonkeyAzurePortalObject @params
            }
        }
        catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $InformationAction;
                Tags = @('AzurePortalWhatIfError');
            }
            Write-Warning @msg
        }
    }
    End{
        if($null -ne $whatIf){
            $User | Add-Member NoteProperty -name whatIf -value $whatIf -Force
        }
        else{
            $User | Add-Member NoteProperty -name whatIf -value $null -Force
        }
        return $User
    }
}

