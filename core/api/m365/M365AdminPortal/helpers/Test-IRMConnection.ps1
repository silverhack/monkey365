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

Function Test-IRMConnection {
    <#
        .SYNOPSIS
		Test IRM connection

        .DESCRIPTION
		Test IRM connection

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-IRMConnection
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [OutputType([System.Boolean])]
	Param ()
    Begin{
        $requestHeader = $null
        #Getting environment
		$Environment = $O365Object.Environment
        #Get Access Token from IRM
		$Authentication = $O365Object.auth_tokens.AADRM
        if ($null -ne $Authentication) {
			#Set Authorization Header
			$AuthHeader = ("MSOID {0}" -f $Authentication.AccessToken)
			$requestHeader = @{ "Authorization" = $AuthHeader }
		}
    }
    Process{
        if($null -ne $requestHeader){
            $url = ("{0}/Configuration" -f $Environment.aadrm_service_locator)
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
                            Write-Warning ("{0}. {1}" -f $result.StatusCode, $rst.ErrorDetail)
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

