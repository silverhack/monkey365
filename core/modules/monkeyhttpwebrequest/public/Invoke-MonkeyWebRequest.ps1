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

Function Invoke-MonkeyWebRequest{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-HttpWebRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, position=0)]
        [System.Uri]$Url,

        [Parameter(Mandatory = $false, HelpMessage='HttpClient')]
        [System.Net.Http.HttpClient]$Client,

        [parameter(Mandatory=$False, HelpMessage='Request method')]
        [ValidateSet("GET","POST","PUT","HEAD")]
        [String]$Method = "GET",

        [parameter(Mandatory=$False, HelpMessage='Accept')]
        [Object[]]$Accept,

        [parameter(Mandatory=$False, HelpMessage='Content Type')]
        [String]$ContentType,

        [parameter(Mandatory=$False, HelpMessage='Referer')]
        [String]$Referer,

        [Parameter(Mandatory = $false, HelpMessage='Timeout threshold for request operations in timespan format')]
        [int32]$TimeOut = 60,

        [parameter(Mandatory=$False, HelpMessage='cookies')]
        [Object[]]$Cookies,

        [parameter(Mandatory=$False, HelpMessage='Cookie container')]
        [System.Net.CookieContainer]$CookieContainer,

        [parameter(Mandatory=$False, HelpMessage='user agent')]
        [String]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:72.0) Gecko/20100101 Firefox/72.0",

        [parameter(Mandatory=$False, HelpMessage='Headers as hashtable')]
        [System.Collections.Hashtable]$Headers,

        [parameter(Mandatory=$False, HelpMessage='POST PUT data')]
        [String]$Data,

        [parameter(Mandatory=$False, HelpMessage='Allows autoredirect')]
        [int32]$MaxRedirections,

        [parameter(Mandatory=$False, HelpMessage='return RAW response')]
        [switch]$RawResponse,

        [parameter(Mandatory=$False, HelpMessage='Show response headers')]
        [switch]$ShowResponseHeaders,

        [parameter(Mandatory=$False, HelpMessage='Get bytes')]
        [switch]$GetBytes,

        [parameter(Mandatory=$False, HelpMessage='Disable SSL Verification')]
        [switch]$DisableSSLVerification,

        [parameter(Mandatory=$False, HelpMessage='Control redirects')]
        [bool]$AllowAutoRedirect = $True
    )
    Begin{
        $response = $null
        $Verbose = $False;
        $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        if(!$PSBoundParameters.ContainsKey('Timeout')){
            $_timeout = 20;
        }
        else{
            $_timeout = $PSBoundParameters['Timeout']
        }
        #Get command metadata
        $HttpClientMetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-HttpClient")
        $StringContentMetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-StringContent")
        $RequestMessageMetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-HttpRequestMessage")
        #Set new dict
        $newPsboundParams = [ordered]@{}
    }
    Process{
        if($PSBoundParameters.ContainsKey('Client') -and $PSBoundParameters['Client']){
            $httpClient = $PSBoundParameters['Client']
        }
        else{
            if($null -ne $HttpClientMetaData){
                $param = $HttpClientMetaData.Parameters.Keys
                foreach($p in $param.GetEnumerator()){
                    if($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
                #Add verbose, debug, etc..
                [void]$newPsboundParams.Add('InformationAction',$InformationAction)
                [void]$newPsboundParams.Add('Verbose',$Verbose)
                [void]$newPsboundParams.Add('Debug',$Debug)
            }
            #get new http client
            $httpClient = New-HttpClient @newPsboundParams
        }
        #clear dict
        [void]$newPsboundParams.Clear()
        if($null -ne $StringContentMetaData){
            $param = $StringContentMetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
            #Add verbose, debug, etc..
            [void]$newPsboundParams.Add('InformationAction',$InformationAction)
            [void]$newPsboundParams.Add('Verbose',$Verbose)
            [void]$newPsboundParams.Add('Debug',$Debug)
        }
        #Get string content
        $body = New-StringContent @newPsboundParams
        #clear dict
        [void]$newPsboundParams.Clear()
        if($null -ne $RequestMessageMetaData){
            $param = $RequestMessageMetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
            #Add verbose, debug, etc..
            [void]$newPsboundParams.Add('InformationAction',$InformationAction)
            #[void]$newPsboundParams.Add('Verbose',$Verbose)
            [void]$newPsboundParams.Add('Debug',$Debug)
        }
        #Get string content
        $request = New-HttpRequestMessage @newPsboundParams
        #Execute request
        if($null -ne $httpClient -and $null -ne $request -and $null -ne $body){
            $p = @{
                Client = $httpClient;
                Method = $Method;
                Body = $body;
                Request = $request;
                TimeOut = $_timeout;
                RawResponse = $RawResponse;
                InformationAction = $InformationAction;
                Verbose = $Verbose;
                Debug = $Debug;
            }
            $response = Invoke-ClientRequest @p
        }
    }
    End{
        if($null -ne $response){
            if($PSBoundParameters.ContainsKey('GetBytes') -and $PSBoundParameters['GetBytes'].IsPresent -and $response -is [System.Net.Http.HttpContent]){
                try{
                    [byte[]]$bytes = $response.ReadAsByteArrayAsync().GetAwaiter().GetResult()
                    return $bytes
                }
                catch{
                    Write-Error $_
                }
            }
            ElseIf($PSBoundParameters.ContainsKey('RawResponse') -and $PSBoundParameters['RawResponse'].IsPresent -and $response -is [System.Net.Http.HttpResponseMessage]){
                return $response
            }
            else{
                #Get response stream
                try{
                    $rawData = $response.ReadAsStringAsync().GetAwaiter().GetResult();
                    $obj = Convert-RawData -RawObject $rawData -ContentType $response.Headers.ContentType
                    #Dispose object
                    [void]$response.Dispose();
                    #return obj
                    return $obj
                }
                catch{
                    Write-Error $_
                }
            }
        }
    }
}