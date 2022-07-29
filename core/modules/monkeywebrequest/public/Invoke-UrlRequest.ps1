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

Function Invoke-UrlRequest{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-UrlRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$true, position=0,ParameterSetName='Url')]
        [String]$url,

        [parameter(Mandatory=$False, HelpMessage='Request method')]
        [ValidateSet("Connect","Get","Post","Head","Put")]
        [String]$Method = "Get",

        [parameter(Mandatory=$False, HelpMessage='Encoding')]
        [String]$Encoding,

        [parameter(Mandatory=$False, HelpMessage='content type')]
        [String]$Content_Type,

        [parameter(Mandatory=$False, HelpMessage='referer')]
        [String]$Referer,

        [parameter(Mandatory=$False, HelpMessage='Timeout threshold for request operations in timespan format')]
        [timespan]$TimeOut,

        [parameter(Mandatory=$False, HelpMessage='cookies')]
        [Object[]]$Cookies,

        [parameter(Mandatory=$False, HelpMessage='Cookie container')]
        [Object]$CookieContainer,

        [parameter(Mandatory=$False, HelpMessage='user agent')]
        [String]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:72.0) Gecko/20100101 Firefox/72.0",

        [parameter(Mandatory=$False, HelpMessage='Headers as hashtable')]
        [System.Collections.Hashtable]$Headers,

        [parameter(Mandatory=$False, HelpMessage='POST PUT data')]
        [String]$Data,

        [parameter(Mandatory=$False, HelpMessage='Allows autoredirect')]
        [switch]$AllowAutoRedirect,

        [parameter(Mandatory=$False, HelpMessage='return RAW response')]
        [switch]$returnRawResponse,

        [parameter(Mandatory=$False, HelpMessage='Show response headers')]
        [switch]$showResponseHeaders,

        [parameter(Mandatory=$False, HelpMessage='Get bytes')]
        [switch]$GetBytes,

        [parameter(Mandatory=$False, HelpMessage='Disable SSL Verification')]
        [switch]$disableSSLVerification
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
        #Method
        switch ($Method.ToLower()) {
            'connect'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Connect
            }
            'get'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Get
            }
            'post'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Post
            }
            'put'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Put
            }
            'head'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Head
            }
        }
        #Set TimeSpan
        if (!$Timeout){
            $Timeout = [timespan]::Zero
        }
        #Check if should disable SSL
        if($PSBoundParameters.ContainsKey('disableSSLVerification')){
            [ServerCertificateValidationCallback]::Ignore();
        }
    }
    Process{
        #Create Request
        try{
            $request = [System.Net.WebRequest]::Create($Url)
        }
        catch{
            #Get exceptions
            Get-WebRequestException -Exception $_ -Url $Url
        }
        if($null -ne $request -and $request -is [System.Net.HttpWebRequest]){
            #Establish Request Method
            $request.Method = $Method
            #Add keepalive
            $request.KeepAlive = $true
            #Add Headers
            if($Headers){
                foreach($element in $headers.GetEnumerator()){
                    $request.Headers.Add($element.key, $element.value)
                }
            }
            #Control Redirects
            if($AllowAutoRedirect){
                $request.AllowAutoRedirect = $True
            }
            else{
                $request.AllowAutoRedirect = $false
            }
            #Add encoding
            if($Encoding){
                #Add Accept
                $request.Accept = $Encoding
            }
            #Add content-type
            if($Content_Type){
                $request.ContentType = $Content_Type
            }
            #Add Cookie container
            if($CookieContainer){
                $request.CookieContainer = $CookieContainer
            }
            #Add Cookies
            if($Cookies){
                foreach($cookie in $Cookies){
                    $request.Headers.add("Cookie", $cookie)
                }
            }
            #Add referer
            if($Referer){
                $request.Referer = $Referer
            }
            #Add custom User-Agent
            $request.UserAgent = $UserAgent
            #Create the request body if POST or PUT
            if(($Method -eq [System.Net.WebRequestMethods+Http]::Post -or $Method -eq [System.Net.WebRequestMethods+Http]::Put) -and $Data){
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
                $request.ContentLength = $bytes.Length
                [System.IO.Stream] $outputStream = [System.IO.Stream]$request.GetRequestStream()
                $outputStream.Write($bytes,0,$bytes.Length)
                $outputStream.Flush()
                $outputStream.Close()
            }
            elseif(($Method -eq [System.Net.WebRequestMethods+Http]::Post -or $Method -eq [System.Net.WebRequestMethods+Http]::Put) -and -NOT $Data){
                $request.ContentLength = 0
            }
            ## Wait for async task to complete
            $cancelTokenSource = [System.Threading.CancellationTokenSource]::new()
            #Execute Request
            $webTask = $request.GetResponseAsync()
            $webTaskResult = $null
            try{
                #Wait for the task
                $webTaskResult = Wait-WebTask -Task $webTask
            }
            Finally{
                if($null -ne $webTaskResult){
                    #Check if task is not completed
                    if (!$webTaskResult.IsCompleted) {
                        $param = @{
                            Message = ('TimeOut for {0}' -f $url);
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        Write-Verbose @param
                        $cancelTokenSource.Cancel()
                    }
                    $cancelTokenSource.Dispose()
                }
            }
            #Check for faulted tasks
            if($null -ne $webTaskResult){
                if ($webTaskResult.IsFaulted){
                    $param = @{
                        Task = $webTaskResult;
                        Verbose = $Verbose;
                        Debug = $Debug;
                        InformationAction = $InformationAction;
                    }
                    Get-WebTaskException @param
                }
                if ($webTaskResult.IsCanceled) {
                    $param = @{
                        Exception = (New-Object System.Threading.Tasks.TaskCanceledException $webTaskResult);
                        Category = ([System.Management.Automation.ErrorCategory]::OperationStopped);
                        ErrorId = 'NewWebRequestFailureOperationStopped';
                        TargetObject = $url;
                    }
                    Write-Error @param
                }
                else {
                    [System.Net.WebResponse]$response = $webTaskResult.Result
                    #Get Detailed info
                    if($showResponseHeaders -and $response -is [System.Net.HttpWebResponse]){
                        Get-WebResponseDetailedMessage -response $response
                    }
                }
            }
        }
    }
    End{
        if($null -ne [System.Net.ServicePointManager]::ServerCertificateValidationCallback){
            #Back to validations
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
        }
        if($returnRawResponse -and $null -ne $response -and $response -is [System.Net.HttpWebResponse]){
            return $response
            #Close the response stream
            $response.Close()
        }
        elseif($null -ne $response -and $response -is [System.Net.HttpWebResponse]){
            if($GetBytes){
                $memory_stream = New-Object System.IO.MemoryStream
                $response.GetResponseStream().CopyTo($memory_stream)
                [byte[]]$bytes = $memory_stream.ToArray()
                #Close the response stream
                $response.Close()
                #Dispose
                $response.Dispose()
                return $bytes
            }
            else{
                #Get the response stream
                $sr = [System.IO.StreamReader]::new($response.GetResponseStream())
                #Convert Raw Data
                $stringObject = $sr.ReadToEndAsync().GetAwaiter().GetResult();
                $Rawobject = Convert-RawData -RawObject $stringObject -ContentType $response.ContentType
                #Close Stream reader
                $sr.Close()
                $sr.Dispose()
                #Close the response stream
                $response.Close()
                #Dispose
                $response.Dispose()
                return $Rawobject
            }
        }
    }
}
