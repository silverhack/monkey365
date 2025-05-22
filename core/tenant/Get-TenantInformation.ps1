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
# See the License for the specIfic language governing permissions and
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
    #Create hashtable
    $tenantInfo= [PsCustomObject]@{
        tenantName = $null;
        tenantId = $null;
        companyInfo = $null;
        sku = $null;
        domains = $null;
        myDomain = $null;
        licensing = $null;
    }
    If($O365Object.auth_tokens.MSGraph -and $O365Object.TenantId){
        Try{
            #Write message
            $msg = @{
                MessageData = ($message.AADTenantInfoMessage -f $O365Object.TenantId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                Tags = @('AADTenantInfo');
            }
            Write-Verbose @msg
            #Get Auth from old graph
            $msgraph_auth = $O365Object.auth_tokens.MSGraph
            #Get Tenant Origin
            If($O365Object.isValidTenantGuid -eq $false){
                $tid = Read-JWTtoken -token $O365Object.auth_tokens.MSGraph.AccessToken | Select-Object -ExpandProperty tid -ErrorAction Ignore
            }
            Else{
                $tid = $O365Object.TenantId
            }
            #Get tenant details
            $Tenant = Get-MonkeyMSGraphOrganization -TenantId $tid
            If($Tenant){
                #Set Tenant info var
                Set-Variable Tenant -Value $Tenant -Scope Script -Force
                If($O365Object.isConfidentialApp){
                    #Set Userprincipalname var
                    If($msgraph_auth.psobject.Properties.Item('clientId')){
                        Set-Variable userPrincipalName -Value $msgraph_auth.clientId.ToString() -Scope Script -Force
                        $O365Object.userPrincipalName = $msgraph_auth.clientId.ToString()
                    }
                    Else{
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
                Else{
                    #Set Userprincipalname var
                    If($msgraph_auth.psobject.Properties.Item('UserInfo')){
                        $O365Object.userPrincipalName = $msgraph_auth.UserInfo.DisplayableId.ToString()
                        Set-Variable userPrincipalName -Value $msgraph_auth.UserInfo.DisplayableId.ToString() -Scope Script -Force
                    }
                    ElseIf($msgraph_auth.psobject.Properties.Item('userPrincipalName')){
                        $O365Object.userPrincipalName = $msgraph_auth.userPrincipalName
                        Set-Variable userPrincipalName -Value $msgraph_auth.userPrincipalName -Scope Script -Force
                    }
                    ElseIf($msgraph_auth.psobject.Properties.Item('Account')){
                        $O365Object.userPrincipalName = $msgraph_auth.Account.Username
                        Set-Variable userPrincipalName -Value $msgraph_auth.Account.Username -Scope Script -Force
                    }
                    Else{
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
                $tenantInfo.tenantName = $Tenant.displayName
                $tenantInfo.companyInfo = $Tenant
                $tenantInfo.tenantId = $Tenant.Id
            }
            #Get subscribed SKUs
            $SKus = Get-MonkeyMSGraphSuscribedSku
            If($SKus){
                #Set property
                $tenantInfo.sku = $SKus
                #Get licensing info from current tenant
                $licensingInfo = Get-TenantLicensingInfo -SKU $SKus
                #Set property
                $tenantInfo.licensing = $licensingInfo;
            }
            #Get Domains
            $tenantInfo.domains = Get-MonkeyMSGraphDomain
            If($null -ne $tenantInfo.domains){
                #Set property
                $tenantInfo.myDomain = $tenantInfo.domains | Where-Object {$_.IsDefault -eq $true}
            }
            #return Obj
            return $tenantInfo
        }
        Catch{
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
    Else{
        $msg = @{
            MessageData = $message.O365TenantInfoError;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            Tags = @('AADTenantError');
        }
        Write-Warning @msg
    }
}

