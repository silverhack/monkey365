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


Function Get-MonkeyAzSecurityAlert{
    <#
        .SYNOPSIS
		Plugin to extract Security alerts from Azure

        .DESCRIPTION
		Plugin to extract Security alerts from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSecurityAlert
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
        $AzureAlerts = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureAlerts"} | Select-Object -ExpandProperty resource
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure alerts", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureAlerts');
        }
        Write-Information @msg
        $params = @{
            Authentication = $rm_auth;
            Provider = $AzureAlerts.provider;
            ObjectType = 'alerts';
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $AzureAlerts.api_version;
        }
        $all_alerts = Get-MonkeyRMObject @params
        #Get primary object
        $AllAlerts = @()
        foreach($Alert in $all_alerts){
            $Properties = $Alert.properties | Select-Object @{Name='AlertName';Expression={$Alert.name}},`
                            vendorName, alertDisplayName, detectedTimeUtc, actionTaken,`
                            reportedSeverity, compromisedEntity, reportedTimeUtc, @{Name='ThreatName';Expression={$Alert.properties.extendedProperties.name}},`
                            @{Name='Path';Expression={$Alert.properties.extendedProperties.path}},@{Name='Category';Expression={$Alert.properties.extendedProperties.category}}
            $Properties.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SecurityAlerts')
            $AllAlerts+=$Properties
        }
    }
    End{
        if($AllAlerts){
            $AllAlerts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SecurityAlerts')
            [pscustomobject]$obj = @{
                Data = $AllAlerts
            }
            $returnData.aad_security_alerts = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure alerts", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureAlertsEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
