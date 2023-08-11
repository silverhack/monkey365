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

Function Invoke-ClientRequest{
    <#
        .SYNOPSIS
        Invoke request

        .DESCRIPTION
        Invoke request

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-ClientRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$False, HelpMessage='HTTP client')]
        [System.Net.Http.HttpClient]$Client,

        [parameter(Mandatory=$False, HelpMessage='HTTP Method')]
        [ValidateSet("GET","POST","PUT","HEAD")]
        [System.Net.Http.HttpMethod]$Method,

        [parameter(Mandatory=$False, HelpMessage='Body')]
        [System.Net.Http.StringContent]$Body,

        [parameter(Mandatory=$False, HelpMessage='Request')]
        [System.Net.Http.HttpRequestMessage]$Request,

        [Parameter(Mandatory = $false, HelpMessage='Timeout threshold for request operations in timespan format')]
        [int32]$TimeOut = 20,

        [parameter(Mandatory=$False, HelpMessage='return RAW response')]
        [switch]$RawResponse
    )
    Begin{
        $webTaskResult = $null;
        $requestTimeout = [Timespan]::FromSeconds($TimeOut);
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
    }
    Process{
        $cancelTokenSource = [System.Threading.CancellationTokenSource]::new($requestTimeout)
        #Add contentType
        Switch ($Method.Method.ToLower()) {
            'get'
            {
                #Avoid request body error with GET requests
                #Add content to body
                if ($PSEdition -eq 'Core'){
                    $Request.Content = $Body
                }
                try{
                    $webTask = $Client.SendAsync($Request, $cancelTokenSource.Token);
                    #Wait for the task
                    $webTaskResult = Wait-WebTask -Task $webTask
                }
                catch{
                    Write-Warning $_
                }
            }
            'head'
            {
                #Add content to body
                $Request.Content = $Body
                try{
                    $webTask = $Client.SendAsync($Request, $cancelTokenSource.Token);
                    #Wait for the task
                    $webTaskResult = Wait-WebTask -Task $webTask
                }
                catch{
                    Write-Warning $_
                }
            }
            'post'
            {
                #Add content to body
                $Request.Content = $Body
                try{
                    $webTask = $Client.SendAsync($Request, $cancelTokenSource.Token);
                    #Wait for the task
                    $webTaskResult = Wait-WebTask -Task $webTask
                }
                catch{
                    Write-Warning $_
                }
            }
            'put'
            {
                #Add content to body
                $Request.Content = $Body
                try{
                    $webTask = $Client.SendAsync($Request, $cancelTokenSource.Token);
                    #Wait for the task
                    $webTaskResult = Wait-WebTask -Task $webTask
                }
                catch{
                    Write-Warning $_
                }
            }
            Default
            {
                #Add content to body
                $Request.Content = $Body
                try{
                    $webTask = $Client.SendAsync($Request, $cancelTokenSource.Token);
                    #Wait for the task
                    $webTaskResult = Wait-WebTask -Task $webTask
                }
                catch{
                    Write-Warning $_
                }
            }
        }
        $cancelTokenSource.Cancel()
        $cancelTokenSource.Dispose()
    }
    End{
        if($null -ne $webTaskResult){
            #Check if task is not completed
            if (!$webTaskResult.IsCompleted) {
                $param = @{
                    Message = ('TimeOut for {0}' -f $Request.RequestUri);
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
                Write-Verbose @param
                $p = @{
                    ErrorResponse = $webTaskResult.Result;
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction
                }
                Get-HttpResponseError @p
            }
            elseif ($webTaskResult.IsFaulted){
                $param = @{
                    Message = ('Task faulted');
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
                Write-Verbose @param
                $p = @{
                    ErrorResponse = $webTaskResult.Result;
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction
                }
                Get-HttpResponseError @p
            }
            elseif ($webTaskResult.IsCanceled) {
                $param = @{
                    Message = ('Task cancelled');
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
                Write-Verbose @param
            }
            else{
                If($PSBoundParameters.ContainsKey('RawResponse') -and $PSBoundParameters['RawResponse'].IsPresent){
                    return $webTaskResult.Result;
                }
                Elseif($webTaskResult.Result.IsSuccessStatusCode){
                    return $webTaskResult.Result.Content
                }
                else{
                    Write-Warning ("[{0}] {1}" -f $webTaskResult.Result.StatusCode, $webTaskResult.Result.RequestMessage.RequestUri.AbsoluteUri)
                    $p = @{
                        ErrorResponse = $webTaskResult.Result;
                        Verbose = $Verbose;
                        Debug = $Debug;
                        InformationAction = $InformationAction
                    }
                    Get-HttpResponseError @p
                }
            }
        }
    }
}