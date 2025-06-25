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
    Process{
        Try{
            If($O365Object.auth_tokens.MSGraph -and $O365Object.TenantId){
                #Write message
                $msg = @{
                    MessageData = ($message.AADTenantInfoMessage -f $O365Object.TenantId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Tags = @('EIDTenantInfo');
                }
                Write-Verbose @msg
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
                        If($O365Object.auth_tokens.MSGraph.psobject.Properties.Item('clientId')){
                            Set-Variable userPrincipalName -Value $O365Object.auth_tokens.MSGraph.clientId.ToString() -Scope Script -Force
                            $O365Object.userPrincipalName = $O365Object.auth_tokens.MSGraph.clientId.ToString()
                        }
                        Else{
                            $msg = @{
                                MessageData = $message.AADUserErrorMessage;
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'warning';
                                Tags = @('EIDUserPrincipalNameError');
                            }
                            Write-Warning @msg
                            Set-Variable userPrincipalName -Value $null -Scope Script -Force
                            $O365Object.userPrincipalName = $O365Object.initParams.ClientId
                        }
                    }
                    Else{
                        #Set Userprincipalname var
                        If($O365Object.auth_tokens.MSGraph.psobject.Properties.Item('UserInfo')){
                            $O365Object.userPrincipalName = $O365Object.auth_tokens.MSGraph.UserInfo.DisplayableId.ToString()
                            Set-Variable userPrincipalName -Value $O365Object.auth_tokens.MSGraph.UserInfo.DisplayableId.ToString() -Scope Script -Force
                        }
                        ElseIf($O365Object.auth_tokens.MSGraph.psobject.Properties.Item('userPrincipalName')){
                            $O365Object.userPrincipalName = $O365Object.auth_tokens.MSGraph.userPrincipalName
                            Set-Variable userPrincipalName -Value $O365Object.auth_tokens.MSGraph.userPrincipalName -Scope Script -Force
                        }
                        ElseIf($O365Object.auth_tokens.MSGraph.psobject.Properties.Item('Account')){
                            $O365Object.userPrincipalName = $O365Object.auth_tokens.MSGraph.Account.Username
                            Set-Variable userPrincipalName -Value $O365Object.auth_tokens.MSGraph.Account.Username -Scope Script -Force
                        }
                        Else{
                            $msg = @{
                                MessageData = $message.AADUserErrorMessage;
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'warning';
                                Tags = @('EIDUserPrincipalNameError');
                            }
                            Write-Warning @msg
                            Set-Variable userPrincipalName -Value $null -Scope Script -Force
                            $O365Object.userPrincipalName = $null
                        }
                    }
                    #Set properties
                    $O365Object.Tenant.tenantName = $Tenant.displayName
                    $O365Object.Tenant.companyInfo = $Tenant
                    $O365Object.Tenant.tenantId = $Tenant.Id
                    #Get subscribed SKUs
                    $O365Object.Tenant.sku = Get-MonkeyMSGraphSuscribedSku
                    If($null -ne $O365Object.Tenant.sku){
                        #Get licensing info from current tenant
                        $O365Object.Tenant.licensing = Get-TenantLicensingInfo -SKU $O365Object.Tenant.sku
                    }
                    #Get Domains
                    $O365Object.Tenant.domains = Get-MonkeyMSGraphDomain
                    If($null -ne $O365Object.Tenant.domains){
                        #Set property
                        $O365Object.Tenant.myDomain = $O365Object.Tenant.domains | Where-Object {$_.IsDefault -eq $true}
                    }
                }
                Else{
                    #Throw error
                    throw ("[TenantError] {0}: {1}" -f "Unable to get tenant information",$_.Exception.Message)
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
        Catch{
            $msg = @{
                MessageData = $message.O365TenantInfoError;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                Tags = @('EIDTenantError');
            }
            Write-Warning @msg
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                Tags = @('EIDTenantError');
            }
            Write-Verbose @msg
            #Throw error
            throw ("[TenantError] {0}: {1}" -f "Unable to get tenant information",$_.Exception.Message)
        }
    }
}