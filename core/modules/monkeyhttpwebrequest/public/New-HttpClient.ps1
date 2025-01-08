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

Function New-HttpClient{
    <#
        .SYNOPSIS
        Create a new HTTP client

        .DESCRIPTION
        Create a new HTTP client

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HttpClient
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'WithHandler')]
        [System.Net.Http.HttpClientHandler]$Handler,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Accept')]
        [Object[]]$Accept,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Content Type')]
        [String]$ContentType,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Referer')]
        [String]$Referer,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Timeout threshold for request operations in timespan format')]
        [int32]$TimeOut = 20,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='cookies')]
        [Object[]]$Cookies,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Cookie container')]
        [System.Net.CookieContainer]$CookieContainer,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='user agent')]
        [String]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:72.0) Gecko/20100101 Firefox/72.0",

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Headers as hashtable')]
        [System.Collections.Hashtable]$Headers,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Allows autoredirect')]
        [Bool]$AllowAutoRedirect = $true,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Automatic decompresion')]
        [switch]$AutomaticDecompression,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage="Maximum redirection")]
        [ValidateRange(1,65535)]
        [int32]$MaxRedirections,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default', HelpMessage='Disable SSL Verification')]
        [switch]$DisableSSLVerification
    )
    Begin{
        $httpTimeout = [Timespan]::FromSeconds($TimeOut*2);
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
        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            'WithHandler' {
                $client = [System.Net.Http.HttpClient]::new($Handler);
            }
            'Default' {
                #New client handler
                $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-ClientHandler")
                $newPsboundParams = [ordered]@{}
                if($null -ne $MetaData){
                    $param = $MetaData.Parameters.Keys
                    foreach($p in $param.GetEnumerator()){
                        if($PSBoundParameters.ContainsKey($p)){
                            $newPsboundParams.Add($p,$PSBoundParameters[$p])
                        }
                    }
                }
                #Add verbose, debug
                $newPsboundParams.Add('Verbose',$Verbose)
                $newPsboundParams.Add('Debug',$Debug)
                $newPsboundParams.Add('InformationAction',$InformationAction)
                #Get ClientHandler
                $_handler = New-ClientHandler @newPsboundParams
                if($_handler){
                    $client = [System.Net.Http.HttpClient]::new($_handler);
                }
            }
        }
    }
    Process{
        #Disable keep alive TODO: Add keep alive support
        $client.DefaultRequestHeaders.ConnectionClose = $true;
        #Add User-Agent
        $client.DefaultRequestHeaders.UserAgent.ParseAdd($UserAgent);
        #Set global timeout
        $client.Timeout = $httpTimeout;
        #Add accept
        if($PSBoundParameters.ContainsKey('Accept')){
            foreach($elem in $PSBoundParameters['Accept']){
                try{
                    [System.Net.Http.Headers.MediaTypeWithQualityHeaderValue]$mediaType = [System.Net.Http.Headers.MediaTypeWithQualityHeaderValue]::Parse($elem)
                    [void]$client.DefaultRequestHeaders.Accept.Add($mediaType)
                }
                catch{
                    Write-Verbose ("Accept {0} not supported. Adding without validation" -f $elem)
                    [void]$client.DefaultRequestHeaders.TryAddWithoutValidation('Accept',$elem)
                }
            }
        }
    }
    End{
        return $client
    }
}
