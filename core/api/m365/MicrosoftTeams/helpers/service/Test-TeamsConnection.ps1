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

Function Test-TeamsConnection {
    <#
        .SYNOPSIS
		Test Teams connection

        .DESCRIPTION
		Test Teams connection

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-TeamsConnection
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [OutputType([System.Boolean])]
	Param ()
    Begin{
        $requestHeader = $null
        $Environment = $O365Object.Environment
        #Get Access Token from Teams
		$Authentication = $O365Object.auth_tokens.Teams
        if($null -ne $Authentication){
            #Get Authorization Header
            $methods = $Authentication | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name
            #Get Authorization Header
            if($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
                $AuthHeader = $Authentication.CreateAuthorizationHeader()
            }
            else{
                $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
            }
            #Set Auth header
            $requestHeader = @{
                "x-ms-correlation-id" = (New-Guid).ToString()
                "x-ms-tenant-id" = $Authentication.TenantId
                "Authorization" = $AuthHeader
            }
        }
    }
    Process{
        if($null -ne $requestHeader){
            $url = ("{0}/Teams.Tenant/tenants" -f $Environment.Teams)
            $p = @{
                Url = $url;
                Headers = $requestHeader;
                Method = 'GET';
                UserAgent = $O365Object.userAgent;
                RawResponse = $true;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $result = Invoke-MonkeyWebRequest @p
            if($null -ne $result){
                if($result.IsSuccessStatusCode){
                    return $true
                }
                else{
                    #Get Error
                    $rst = $result.Content.ReadAsStringAsync().Result
                    if($null -ne $rst){
                        #Try to convert to JSON
                        try{
                            $rst = $rst | ConvertFrom-Json
                            Write-Warning ("{0} {1}" -f $rst.message,$rst.action)
                        }
                        catch{
                            Write-Warning "Unable to convert error message to json"
                        }
                    }
                    return $false
                }
            }
        }
    }
    End{
        #Nothing to do here
    }
}