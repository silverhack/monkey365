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


Function Get-MonkeyADUser{
    <#
        .SYNOPSIS
		Plugin to extract users from Azure AD

        .DESCRIPTION
		Plugin to extract users from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Process{
        #create array
        $all_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        $AADConfig = $O365Object.internal_config.azuread
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "users", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphUsers');
        }
        Write-Information @msg
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        $api_version = $O365Object.internal_config.azuread.api_version
        #check if internal version is needed
        if([System.Convert]::ToBoolean($O365Object.internal_config.azuread.dumpAdUsersWithInternalGraphAPI) -and $O365Object.isConfidentialApp -eq $false){
            $api_version = '1.6-internal'
            $msg = @{
                MessageData = ($message.GraphAPISwitchMessage);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphUsersAPISwitch');
            }
            Write-Information @msg
        }
        #Get users
        $params = @{
            Authentication = $AADAuth;
            ObjectType = "users";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $api_version;
        }
        $tmp_users = Get-MonkeyGraphObject @params
        if($tmp_users){
            if([System.Convert]::ToBoolean($AADConfig.GetUserDetails)){
                #Generate vars
                $vars = @{
                    "O365Object"=$O365Object;
                    "WriteLog"=$WriteLog;
                    'Verbosity' = $Verbosity;
                    'InformationAction' = $InformationAction;
                    "all_users"=$all_users;
                }
                $param = @{
                    ScriptBlock = {Get-AADDetailedUser -user $_};
                    ImportCommands = $O365Object.LibUtils;
                    ImportVariables = $vars;
                    ImportModules = $O365Object.runspaces_modules;
                    StartUpScripts = $O365Object.runspace_init;
                    ThrowOnRunspaceOpenError = $true;
                    Debug = $O365Object.VerboseOptions.Debug;
                    Verbose = $O365Object.VerboseOptions.Verbose;
                    Throttle = $O365Object.nestedRunspaceMaxThreads;
                    MaxQueue = $O365Object.MaxQueue;
                    BatchSleep = $O365Object.BatchSleep;
                    BatchSize = $O365Object.BatchSize;
                }
                $all_users = $tmp_users | Invoke-MonkeyJob @param
            }
            else{
                $all_users = $tmp_users;
            }
        }
    }
    End{
        if ($all_users){
            [pscustomobject]$obj = @{
                Data = $all_users
            }
            $returnData.aad_domain_users = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Users", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphUsersEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
