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

Function Get-GitHubActionsOidcToken {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $false, HelpMessage = 'Audience')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Audience = "api://AzureADTokenExchange"
    )
    Begin{
        $requestUri = [Environment]::GetEnvironmentVariable('ACTIONS_ID_TOKEN_REQUEST_URL');
        $requestToken = [Environment]::GetEnvironmentVariable('ACTIONS_ID_TOKEN_REQUEST_TOKEN');
    }
    Process{
        If (-not $requestUri -or -not $requestToken) {
            throw [System.InvalidOperationException]::new(
                'GitHub Actions OIDC is unavailable'
            )
        }
        #Discover separator
        $separator = If ($requestUri.Contains('?')) { '&' } else { '?' }
        #Create URI
        $uri = '{0}{1}audience={2}' -f (
            $requestUri,
            $separator,
            [Uri]::EscapeDataString($Audience)
        )
        #Set headers
        $headers = @{
            Authorization = "Bearer $requestToken"
            Accept        = 'application/json'
          }
        #Set options
        $options = @{
            Method = "GET";
            Uri = $uri;
            Headers = $headers;
            TimeoutSec = 30;
        }
        #Execute query
        Try{
            $response = Invoke-WebRequest @options -UseBasicParsing
            If ($response.StatusCode -ne [System.Net.HttpStatusCode]::OK) {
                throw 'The GitHub OIDC response did not contain a token.'
            }
            $assertionCallback = $response.Content | convertfrom-Json
            #Return value
            return $assertionCallback.value
        }
        Catch{
            throw "GitHub OIDC request failed: $($_.Exception.Message)"
        }
    }
}