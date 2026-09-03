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

Function ConvertTo-Monkey365AccessToken{
    <#
        .SYNOPSIS
        Utility to convert access tokens into a closed version of an AuthenticationTokenResult object

        .DESCRIPTION
        Utility to convert access tokens into a closed version of an AuthenticationTokenResult object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-Monkey365AccessToken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("InjectionRisk.Create", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Access Token")]
        [String]$InputObject
    )
    Process{
        Try{
            #Set Null
            $at_info = $authObject = $null
            #Set authType
            $authType = 'Unknown';
            If($null -ne (Get-Command -Name "Read-JWTtoken" -ErrorAction ignore)){
                Try{
                    $at_info = Read-JWTtoken -token $InputObject | Select-Object appid,app_displayname,idtyp,scp,aud,exp,tid -ErrorAction Ignore
                }
                Catch{
                    Write-Error $_
                }
            }
            If($null -ne $at_info){
                #Check if expired token
                $expiry = [System.DateTimeOffset]::FromUnixTimeSeconds($at_info.exp).UtcDateTime
                $now = [System.DateTime]::Now.ToUniversalTime();
                If($expiry -ge $now){
                    #Get idTyp
                    If($null -ne $at_info.idtyp){
                        If($at_info.idtyp.ToLower() -eq "user"){
                            $authType = 'Interactive'
                        }
                        Else{
                            $authType = 'Certificate_Credentials'
                        }
                    }
                    #Set PsCustomObject
                    $authObject = [PsCustomObject]@{
                        AuthType = $authType;
                        resource = $at_info.aud;
                        clientId = $at_info.appid;
                        renewable = $false;
                        AccessToken = $InputObject;
                        ExpiresOn = [System.DateTimeOffset]::FromUnixTimeSeconds($at_info.exp);
                        TenantId = $at_info.tid;
                        Scopes = [System.Collections.Generic.HashSet[System.String]]::new()
                    }
                    #Set Scopes
                    #Add .default
                    [void]$authObject.Scopes.Add(('{0}/.default' -f $authObject.resource));
                    If($null -ne $at_info.scp -and $at_info.idtyp.ToLower() -eq "user"){
                        ForEach($scope in @($at_info.scp).GetEnumerator()){
                            [void]$authObject.Scopes.Add(('{0}/{1}' -f $authObject.resource,$scope));
                        }
                    }
                    #Add IsNearExpiry script method
                    $authObject | Add-Member -Type ScriptMethod -Name IsNearExpiry -Value {
                        return ([System.Datetime]::UtcNow -gt $this.ExpiresOn.UtcDateTime.AddMinutes(-15))
                    }
                    #return object
                    return $authObject;
                }
                Else{
                    Write-Warning ("Expired token for {0}" -f $at_info.aud)
                }
            }
        }
        Catch{
            Write-Error $_
        }
    }
}
