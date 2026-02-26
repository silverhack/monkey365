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

Function Get-MonkeySubscriptionInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySubscriptionInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Authentication object')]
        [Object]$AuthObject,

        [Parameter(Mandatory = $false, HelpMessage = 'Endpoint')]
        [String]$Endpoint
    )
    Try{
        #Get Authorization Header
        $methods = $AuthObject | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name
        #Get Authorization Header
        If($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
            $AuthHeader = $AuthObject.CreateAuthorizationHeader()
        }
        Else{
            $AuthHeader = ("Bearer {0}" -f $AuthObject.AccessToken)
        }
        $requestHeader = @{
            "Authorization" = $AuthHeader
        }
        $Server = [System.Uri]::new($Endpoint)
        $uri = [System.Uri]::new($Server,"/subscriptions?api-version=2022-09-01")
        $final_uri = $uri.ToString()
        try{
            $p = @{
                Uri = $final_uri;
                Method = "Get";
                Headers = $requestHeader;
                ContentType = 'application/json'
            }
            $subs = Invoke-RestMethod @p
            If($subs.Value){
                return $subs.Value
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
    Catch{
        Write-Error $_.Exception
    }
}