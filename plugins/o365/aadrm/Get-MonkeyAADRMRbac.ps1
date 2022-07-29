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


Function Get-MonkeyAADRMRbac{
    <#
        .SYNOPSIS
		Plugin to get information about RBAC from AADRM

        .DESCRIPTION
		Plugin to get information about RBAC from AADRM

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADRMRbac
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
        #Get Access Token from AADRM
        $access_token = $O365Object.auth_tokens.AADRM
        #Get AADRM Url
        $url = $O365Object.Environment.aadrm_service_locator
        if($null -ne $access_token){
            #Set Authorization Header
            $AuthHeader = ("MSOID {0}" -f $access_token.AccessToken)
            $requestHeader = @{"Authorization" = $AuthHeader}
        }
        #Create AADRM object
        $aadrm_rbac = New-Object -TypeName PSCustomObject
    }
    Process{
        if($requestHeader -and $url){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Office 365 Rights Management: RBAC users", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AADRMRBACStatus');
            }
            Write-Information @msg
            $url_global = ("{0}/Administrators/Roles/GlobalAdministrator" -f $url)
            $params = @{
                Url = $url_global;
                Method = 'Get';
                Content_Type = 'application/json; charset=utf-8';
                Headers = $requestHeader;
                disableSSLVerification = $true;
            }
            #call AADRM endpoint
            $AADRM_Global_Admins = Invoke-UrlRequest @params
            if($AADRM_Global_Admins){
                $aadrm_rbac | Add-Member -type NoteProperty -name Global_Admins -value $AADRM_Global_Admins
            }
            else{
                $aadrm_rbac | Add-Member -type NoteProperty -name Global_Admins -value $false
            }
            #Get Connector admins
            $url_connector = ("{0}/Administrators/Roles/ConnectorAdministrator" -f $url)
            $params = @{
                Url = $url_connector;
                Method = 'Get';
                Content_Type = 'application/json; charset=utf-8';
                Headers = $requestHeader;
                disableSSLVerification = $true;
            }
            #call AADRM endpoint
            $AADRM_Connector_Admins = Invoke-UrlRequest @params
            if($AADRM_Connector_Admins){
                $aadrm_rbac | Add-Member -type NoteProperty -name Connector_Admins -value $AADRM_Connector_Admins
            }
            else{
                $aadrm_rbac | Add-Member -type NoteProperty -name Connector_Admins -value $false
            }
        }
    }
    End{
        if($aadrm_rbac){
            $aadrm_rbac.PSObject.TypeNames.Insert(0,'Monkey365.AADRM.RBAC')
            [pscustomobject]$obj = @{
                Data = $aadrm_rbac
            }
            $returnData.o365_aadrm_rbac = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Office 365 Rights Management: RBAC users", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AADRMRBACEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
