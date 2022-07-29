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


Function Get-MonkeyFormsTenantInformation{
    <#
        .SYNOPSIS
		Plugin to get information about Microsoft Forms tenant settings

        .DESCRIPTION
		Plugin to get information about Microsoft Forms tenant settings

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyFormsTenantInformation
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
        $forms_tenant_settings = $null;
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Microsoft Forms. Tenant Settings", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('FormsTenantInfo');
        }
        if($null -ne $O365Object.auth_tokens.Forms){
            $authHeader = @{
                Authorization = $O365Object.auth_tokens.Forms.CreateAuthorizationHeader()
            }
            $url = ("{0}/formapi/api/GetFormsTenantSettings" -f $O365Object.Environment.Forms)
            $params = @{
                Url = $url;
                Method = 'Get';
                Content_Type = 'application/json';
                Headers = $authHeader;
            }
            #call tenant settings
            $forms_tenant_settings = Invoke-UrlRequest @params
        }
        else{
            $msg = @{
                MessageData = ("Unable to get tenant's information from Microsoft Forms");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('FormsTenantInfoWarning');
            }
            Write-Warning @msg
        }
    }
    End{
        if($null -ne $forms_tenant_settings){
            $forms_tenant_settings.PSObject.TypeNames.Insert(0,'Monkey365.Forms.TenantSettings')
            [pscustomobject]$obj = @{
                Data = $forms_tenant_settings
            }
            $returnData.o365_forms_tenant_settings = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Microsoft 365 Forms. Tenant settings", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('FormsTenantInfoEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
