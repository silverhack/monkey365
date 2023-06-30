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

Function Get-TenantInformation{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-TenantInformation
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    if($O365Object.auth_tokens.MSGraph -and $O365Object.TenantId){
        try{
            #Write message
            $msg = @{
                MessageData = ($message.AADTenantInfoMessage -f $O365Object.TenantId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                Tags = @('AADTenantInfo');
            }
            Write-Verbose @msg
            #Create hashtable
            $tenantInfo= [ordered]@{
                TenantName = $null;
                TenantId = $null;
                CompanyInfo = $null;
                SKU = $null;
                Domains = $null;
                MyDomain = $null;
            }
            #Get Auth from old graph
            $msgraph_auth = $O365Object.auth_tokens.MSGraph
            #Get tenant details
            $Tenant = Get-MonkeyMSGraphOrganization -TenantId $O365Object.TenantId
            if($Tenant){
                #Set Tenant info var
                Set-Variable Tenant -Value $Tenant -Scope Script -Force
                if($O365Object.isConfidentialApp){
                    #Set Userprincipalname var
                    if($msgraph_auth.psobject.Properties.Item('clientId')){
                        Set-Variable userPrincipalName -Value $msgraph_auth.clientId.ToString() -Scope Script -Force
                        $O365Object.userPrincipalName = $msgraph_auth.clientId.ToString()
                    }
                    else{
                        $msg = @{
                            MessageData = $message.AADUserErrorMessage;
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            Tags = @('AADUserPrincipalNameError');
                        }
                        Write-Warning @msg
                        Set-Variable userPrincipalName -Value $null -Scope Script -Force
                        $O365Object.userPrincipalName = $O365Object.initParams.ClientId
                    }
                }
                else{
                    #Set Userprincipalname var
                    if($msgraph_auth.psobject.Properties.Item('UserInfo')){
                        $O365Object.userPrincipalName = $msgraph_auth.UserInfo.DisplayableId.ToString()
                        Set-Variable userPrincipalName -Value $msgraph_auth.UserInfo.DisplayableId.ToString() -Scope Script -Force
                    }
                    elseif($msgraph_auth.psobject.Properties.Item('userPrincipalName')){
                        $O365Object.userPrincipalName = $msgraph_auth.userPrincipalName
                        Set-Variable userPrincipalName -Value $msgraph_auth.userPrincipalName -Scope Script -Force
                    }
                    elseif($msgraph_auth.psobject.Properties.Item('Account')){
                        $O365Object.userPrincipalName = $msgraph_auth.Account.Username
                        Set-Variable userPrincipalName -Value $msgraph_auth.Account.Username -Scope Script -Force
                    }
                    else{
                        $msg = @{
                            MessageData = $message.AADUserErrorMessage;
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            Tags = @('AADUserPrincipalNameError');
                        }
                        Write-Warning @msg
                        Set-Variable userPrincipalName -Value $null -Scope Script -Force
                        $O365Object.userPrincipalName = $null
                    }
                }
                #Set properties
                $tenantInfo.TenantName = $Tenant.displayName
                $tenantInfo.CompanyInfo = $Tenant
                $tenantInfo.TenantId = $Tenant.Id
            }
            #Get subscribed SKUs
            $SKus = Get-MonkeyMSGraphSuscribedSku
            if($SKus){
                #Set property
                $tenantInfo.SKU = $SKus
            }
            #Get Domains
            $tenantInfo.Domains = Get-MonkeyMSGraphDomain
            if($null -ne $tenantInfo.Domains){
                #Set property
                $tenantInfo.MyDomain = $tenantInfo.Domains | Where-Object -Property IsDefault -EQ "True"
            }
            #Return object
            $tenant_object = New-Object PSObject -Property $tenantInfo
            return $tenant_object
        }
        catch{
            $msg = @{
                MessageData = $message.O365TenantInfoError;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                Tags = @('AADTenantError');
            }
            Write-Warning @msg
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                Tags = @('AADTenantError');
            }
            Write-Debug @msg
        }
    }
    else{
        $msg = @{
            MessageData = $message.O365TenantInfoError;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            Tags = @('AADTenantError');
        }
        Write-Warning @msg
    }
}
