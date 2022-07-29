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


Function Get-MonkeyAzResourceLock{
    <#
        .SYNOPSIS
		Plugin to get management locks for a resource

        .DESCRIPTION
		Plugin to get management locks for a resource

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzResourceLock
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
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Config
        $locks_config = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureLocks"} | Select-Object -ExpandProperty resource
        #Set array
        $all_locks = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Locks", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureLocksInfo');
        }
        Write-Information @msg
        if($null -ne $O365Object.all_resources){
            foreach($resource in $O365Object.all_resources){
                $msg = @{
                    MessageData = ("Getting locks from {0}" -f $resource.name);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $InformationAction;
                    Tags = @('AzureLocksInfo');
                }
                Write-Verbose @msg
                #Get lock
                $URI = ("{0}{1}/providers/Microsoft.Authorization/locks?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager, `
                            $resource.id,$locks_config.api_version)

                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $resource_lock_info = Get-MonkeyRMObject @params
                if($null -ne $resource_lock_info){
                    $lock_info = [PsCustomObject]@{
                        id = $resource.id;
                        name = $resource.name;
                        sku = $resource.sku;
                        kind = $resource.kind;
                        location = $resource.location;
                        locks = $resource_lock_info;
                    }
                    $all_locks+= $lock_info
                }
            }
        }
    }
    End{
        if($all_locks){
            $all_locks.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Locks')
            [pscustomobject]$obj = @{
                Data = $all_locks
            }
            $returnData.az_locks = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Locks", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureLocksEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
