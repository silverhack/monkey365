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


Function Get-MonkeyAzSecCenterBuiltin{
    <#
        .SYNOPSIS
		Azure plugin to get Security Center Builtin

        .DESCRIPTION
		Azure plugin to get Security Center Builtin

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSecCenterBuiltin
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
        #get Config
        $azure_auth_config = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureAuthorization"} | Select-Object -ExpandProperty resource
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Microsoft Defender for Cloud BuiltIn", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureSecCenterInfo');
        }
        Write-Information @msg
        #List Security Center Bulletin
        $params = @{
            Authentication = $rm_auth;
            Provider = $azure_auth_config.provider;
            ObjectType = "policyAssignments/SecurityCenterBuiltIn";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = "2019-01-01";
        }
        $security_center_builtin = Get-MonkeyRMObject @params
        $acs_entries = @()
        foreach ($acs_entry in $security_center_builtin.properties.parameters.psobject.Properties){
            $Unit_Policy = New-Object -TypeName PSCustomObject
            $Unit_Policy | Add-Member -type NoteProperty -name PolicyName -value $acs_entry.name.ToString()
            $Unit_Policy | Add-Member -type NoteProperty -name Status -value $acs_entry.value.value.ToString()
            $Unit_Policy.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ACS_Policy')
            $acs_entries+=$Unit_Policy
        }
    }
    End{
        if($acs_entries){
            $acs_entries.PSObject.TypeNames.Insert(0,'Monkey365.Azure.securitycenter.acsbuiltin.parameters')
            [pscustomobject]$obj = @{
                Data = $acs_entries
            }
            $returnData.az_asc_builtin_policies = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft Defender for Cloud BuiltIn", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureKeySecCenterEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
