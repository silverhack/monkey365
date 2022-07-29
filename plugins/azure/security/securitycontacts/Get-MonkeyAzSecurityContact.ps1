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


Function Get-MonkeyAzSecurityContact{
    <#
        .SYNOPSIS
		Azure plugin to get Security Contacts

        .DESCRIPTION
		Azure plugin to get Security Contacts

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSecurityContact
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
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get config
        $azureContactConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureContacts"} | Select-Object -ExpandProperty resource
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Security Contacts", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureSecContactInfo');
        }
        Write-Information @msg
        #List All Security Contacts
        $params = @{
            Authentication = $rm_auth;
            Provider = $azureContactConfig.provider;
            ObjectType = "securityContacts";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $azureContactConfig.api_version;
        }
        $securityContacts = Get-MonkeyRMObject @params
        #Create array
        $allsecurityContacts = @()
        foreach ($account in $securityContacts){
            $Properties = $account | Select-Object @{Name='id';Expression={$account.id}},`
                                    @{Name='rawObject';Expression={$account}},`
                                    @{Name='name';Expression={$account.name}},`
                                    @{Name='properties';Expression={$account.properties}},`
                                    @{Name='email';Expression={$account.properties.email}},`
                                    @{Name='phone';Expression={$account.properties.phone}},`
                                    @{Name='alertNotifications';Expression={$account.properties.alertNotifications}},`
                                    @{Name='alertsToAdmins';Expression={$account.properties.alertsToAdmins}}

            #Decorate object
            $Properties.PSObject.TypeNames.Insert(0,'Monkey365.Azure.securityContact')
            $allsecurityContacts+=$Properties
        }
    }
    End{
        if($allsecurityContacts){
            $allsecurityContacts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.securityContacts')
            [pscustomobject]$obj = @{
                Data = $allsecurityContacts
            }
            $returnData.az_security_contacts = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Security Contacts", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureKeySecContactEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
