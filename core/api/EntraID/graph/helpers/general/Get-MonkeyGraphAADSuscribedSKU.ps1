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


Function Get-MonkeyGraphAADSuscribedSKU{
    <#
        .SYNOPSIS
		Get subscribed SKus from Azure AD

        .DESCRIPTION
		Get subscribed SKus from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphAADSuscribedSKU
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="TenantId")]
        [String]$TenantId
    )
    Begin{
        #Set Empty GUID
        $EmptyGuid = [System.Guid]::empty
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure AD Auth
        $aad_auth = $O365Object.auth_tokens.Graph
        #Get Conf
        try{
            $aadConf = $O365Object.internal_config.entraId.provider.graph
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
        $isValidTenantId = $true
        #check Tenant
        if($TenantId){
            $isValidTenantId = [System.Guid]::TryParse($TenantId,[System.Management.Automation.PSReference]$EmptyGuid)
        }
        else{
            $isValidTenantId = $false
        }
    }
    Process{
        if($isValidTenantId -eq $false){
            $TenantId = "/myOrganization"
        }
        $p = @{
            Environment = $Environment;
            Authentication = $aad_auth;
            TenantId = $TenantId;
            ObjectType = 'subscribedSkus';
            APIVersion = $aadConf.api_version;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $SubscribedSKu = Get-MonkeyGraphObject @p
    }
    End{
        $SubscribedSKu
    }
}
