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


Function Get-MonkeyAzLogProfile{
    <#
        .SYNOPSIS
		Plugin to get log profile from Azure

        .DESCRIPTION
		Plugin to get log profile from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzLogProfile
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
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Config
        $azure_log_config = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureLogProfile"} | Select-Object -ExpandProperty resource
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Log config", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureLogConfigInfo');
        }
        Write-Information @msg
        #Get All locations
        $URI = ("{0}{1}/locations?api-Version={2}" `
                -f $O365Object.Environment.ResourceManager,$O365Object.current_subscription.id,'2016-06-01')
        $params = @{
            Authentication = $rm_auth;
            OwnQuery = $URI;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
        }
        $azure_locations = Get-MonkeyRMObject @params
        #Get log profile
        $params = @{
            Authentication = $rm_auth;
            Provider = $azure_log_config.provider;
            ObjectType = 'logprofiles/default';
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $azure_log_config.api_version;
        }
        $Azure_Log_Profile = Get-MonkeyRMObject @params
        if($Azure_Log_Profile.id){
            #Check if storage account is using Own key
            if($Azure_Log_Profile.properties.storageAccountId){
                $strId = $Azure_Log_Profile.properties.storageAccountId
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$strId,'2019-06-01')
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $my_straccount = Get-MonkeyRMObject @params
                if($my_straccount.properties.encryption.keyvaultproperties.keyvaulturi -and $my_straccount.properties.encryption.keyvaultproperties.keyname){
                    $Azure_Log_Profile | Add-Member -type NoteProperty -name storageAccountUsingOwnKey -value $true
                    $Azure_Log_Profile | Add-Member -type NoteProperty -name ConfiguredStorageAccount -value $my_straccount
                }
                else{
                    $Azure_Log_Profile | Add-Member -type NoteProperty -name storageAccountUsingOwnKey -value $false
                    $Azure_Log_Profile | Add-Member -type NoteProperty -name ConfiguredStorageAccount -value $null
                }
            }
            #Check that all regiions (Including global) are checked
            $location_result = $Azure_Log_Profile.properties.locations.Count - $azure_locations.Count
            if($location_result -eq 1){
                $Azure_Log_Profile | Add-Member -type NoteProperty -name activityLogForAllRegions -value $true
            }
            else{
                $Azure_Log_Profile | Add-Member -type NoteProperty -name activityLogForAllRegions -value $false
            }
        }
        else{
            $Azure_Log_Profile = New-Object -TypeName PSCustomObject
            $Azure_Log_Profile | Add-Member -type NoteProperty -name Id -value $null
            $Azure_Log_Profile | Add-Member -type NoteProperty -name name -value "NotConfigured"
            $Azure_Log_Profile | Add-Member -type NoteProperty -name activityLogForAllRegions -value $false
            $Azure_Log_Profile | Add-Member -type NoteProperty -name retentionPolicyEnabled -value $false
            $Azure_Log_Profile | Add-Member -type NoteProperty -name retentionPolicyDays -value 0
        }
    }
    End{
        if($Azure_Log_Profile){
            $Azure_Log_Profile.PSObject.TypeNames.Insert(0,'Monkey365.Azure.LogProfile')
            [pscustomobject]$obj = @{
                Data = $Azure_Log_Profile
            }
            $returnData.az_log_profile = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Log profile", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureLogProfileEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
