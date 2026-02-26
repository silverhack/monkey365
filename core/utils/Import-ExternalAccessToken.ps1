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

function Import-ExternalAccessToken {
    <#
        .SYNOPSIS
        Utility to import external access tokens into internal Monkey365 auth object

        .DESCRIPTION
        Utility to import external access tokens into internal Monkey365 auth object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Import-ExternalAccessToken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    Param (
        [parameter(Mandatory=$True, HelpMessage="Access Token")]
        [Object]$InputObject
    )
    Begin{
        #Set null
        $initialDomain = $spoAdminUrl = $spoUrl = $null;
        #Set Array
        $allAuthObjects = [System.Collections.Generic.List[System.Management.Automation.PsObject]]::new()
        ForEach($at in @($InputObject).Where({$null -ne $_})){
            #Get Access Token
            $accessToken = $at | ConvertTo-Monkey365AccessToken
            If($null -ne $accessToken){
                [void]$allAuthObjects.Add($accessToken);
            }
        }
    }
    Process{
        Try{
            If($allAuthObjects.Count -gt 0){
                #Check if mixed tokens were passed
                $nonMixedTokens = @($allAuthObjects | Select-Object -ExpandProperty TenantId -Unique).Count -eq 1
                If($nonMixedTokens -and $nonMixedTokens -eq $O365Object.TenantId){
                    #Get Tokens for SPO
                    $spoAt = $allAuthObjects.Where({$_.resource -eq '00000003-0000-0ff1-ce00-000000000000'})
                    If($spoAt.Count -gt 0){
                        #Access Token for SharePoint Online detected
                        #Get Token for MSGraph
                        $msGraph = $allAuthObjects.Where({$_.resource -match "https://graph.microsoft.com?.$|.us?.$|microsoftgraph.chinacloudapi.cn?.$";}) | Select-Object -First 1 -ErrorAction Ignore
                        If($null -ne $msGraph){
                            #Get domains
                            $domains = Get-MonkeyMSGraphObject -Authentication $msGraph -Environment $O365Object.Environment -ObjectType domains
                            IF($null -ne $domains){
                                $O365Object.Tenant.MyDomain = @($domains).Where({$_.isDefault}) | Select-Object -ExpandProperty id -ErrorAction Ignore
                            }
                            If($O365Object.initParams.ContainsKey('SpoSites') -and @($O365Object.initParams.SpoSites).Count -gt 0){
                                [uri]$dnsName = $O365Object.initParams.SpoSites | Select-Object -First 1
                                $initialDomain = ("{0}" -f $dnsName.DnsSafeHost)
                            }
                            Else{
                                If($null -ne $domains){
                                    $initialDomain = @($domains).Where({$_.supportedServices -like "*OfficeCommunicationsOnline*" -and $_.isDefault -eq $true}) | Select-Object -ExpandProperty id -ErrorAction Ignore
                                }
                            }
                        }
                        If($null -ne $initialDomain){
                            $CloudType = $O365Object.cloudEnvironment;
                            $sps_p = @{
                                Endpoint = $initialDomain;
                                Environment = $CloudType;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $spoAdminUrl = Get-SharepointAdminUrl @sps_p
                            $spoUrl = Get-SharepointUrl @sps_p
                        }
                        If($null -ne $spoAdminUrl -and $null -ne $spoUrl){
                            #Get Tokens for SPO Admin Url
                            $spoAt = $allAuthObjects.Where({$_.resource -eq '00000003-0000-0ff1-ce00-000000000000'})
                            ForEach($spoToken in $spoAt){
                                #Test site connection
                                $adminConnected = Test-SiteConnection -Authentication $spoToken -Site $spoAdminUrl
                                If($adminConnected){
                                    #Update token and break
                                    $spoToken.resource = $spoAdminUrl;
                                    break
                                }
                            }
                            #Get Tokens for SPO
                            $spoAt = $allAuthObjects.Where({$_.resource -eq '00000003-0000-0ff1-ce00-000000000000'})
                            ForEach($spoToken in $spoAt){
                                #Test site connection
                                $connected = Test-SiteConnection -Authentication $spoToken -Site $spoUrl
                                If($connected){
                                    #Update token and break
                                    $spoToken.resource = $spoUrl;
                                    break
                                }
                            }
                        }
                        Else{
                            $msg = @{
                                MessageData = ($message.SPOTokenImportErrorMessage);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'warning';
                                InformationAction = $O365Object.InformationAction;
                                Tags = @('Monkey365ImportTokenInfo');
                            }
                            Write-Warning @msg
                            #Clear tokens for SPO
                            $allAuthObjects = $allAuthObjects.Where({$_.resource -ne '00000003-0000-0ff1-ce00-000000000000'})
                        }
                    }
                }
                Else{
                    $msg = @{
                        MessageData = ($message.MixedTokensErrorMessage);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365ImportTokenInfo');
                    }
                    Write-Warning @msg
                    #Clear array
                    $allAuthObjects.Clear()
                }
            }
        }
        Catch{
            Write-Error $_
        }
    }
    End{
        If($allAuthObjects.Count -gt 0){
            #Importing tokens
            ForEach($accessToken in $allAuthObjects){
                $tokenResource = Read-JWTtoken -token $accessToken.AccessToken | Select-Object -ExpandProperty aud -ErrorAction Ignore | Get-MSServiceFromAudience
                If($null -ne $tokenResource){
                    $msg = @{
                        MessageData = ($message.ValidTokenInfoMessage -f $tokenResource);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365ImportTokenInfo');
                    }
                    Write-Information @msg
                    $msg = @{
                        MessageData = ($message.ImportTokenInfoMessage);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365ImportTokenInfo');
                    }
                    Write-Information @msg
                    If($tokenResource.ToLower() -eq 'sharepoint'){
                        If($accessToken.resource.ToLower() -match "admin"){
                            $O365Object.auth_tokens.SharePointAdminOnline = $accessToken;
                        }
                        Else{
                            $O365Object.auth_tokens.SharePointOnline = $accessToken;
                        }
                    }
                    ElseIf($tokenResource.ToLower() -eq 'exchangeonline'){
                        $O365Object.auth_tokens.ExchangeOnline = $accessToken;
                        $O365Object.auth_tokens.ComplianceCenter = $accessToken;
                    }
                    Else{
                        $O365Object.auth_tokens.Item($tokenResource) = $accessToken;
                    }
                }
            }
        }
    }
}