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

Function Get-HttpResponseError{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HttpResponseError
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage='HTTP response message')]
        [System.Net.Http.HttpResponseMessage]$ErrorResponse
    )
    try{
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
        #Get url and status code
        $url = $ErrorResponse.RequestMessage.RequestUri
        $StatusCode = ($ErrorResponse.StatusCode.value__).ToString().Trim();
        $Reason = $ErrorResponse.ReasonPhrase
        if($null -ne $Url){
            $param = @{
                Message = ($script:messages.UnableToProcessUrl -f $Url);
                Verbose = $Verbose;
            }
            Write-Verbose @param
        }
        #Write error message
        $param = @{
            Message = ("[{0}]: {1}" -f $StatusCode, $Reason);
            Verbose = $Verbose;
        }
        Write-Verbose @param
        #Get response message
        $rawData = $ErrorResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if($null -eq $ErrorResponse.Content.Headers.ContentType){
            $contentType = 'application/json'
        }
        Else{
            $contentType = $ErrorResponse.Content.Headers.ContentType.MediaType
        }
        $responseBody = Convert-RawData -RawObject $rawData -ContentType $contentType
        if($null -ne $responseBody){
            try{
                if($null -ne ($responseBody.psobject.properties.Item('odata.error'))){
                    $errorCode = $responseBody.'odata.error'.code
                    $errorMessage = $responseBody.'odata.error'.message.value
                    if($null -ne $errorCode){
                        $param = @{
                            Message = $errorCode;
                            Verbose = $Verbose;
                        }
                        Write-Verbose @param
                    }
                    if($null -ne $errorMessage){
                        $param = @{
                            Message = $errorMessage;
                            Verbose = $Verbose;
                        }
                        Write-Verbose @param
                    }
                }
                elseif($null -ne ($responseBody.psobject.properties.Item('error_description'))){
                    $param = @{
                        Message = $responseBody.error_description;
                        Verbose = $Verbose;
                    }
                    Write-Verbose @param
                }
                elseif($null -ne ($responseBody.psobject.properties.Item('error'))){
                    $errorCode = $responseBody.error | Select-Object -ExpandProperty code -ErrorAction Ignore
                    $errorMessage = $responseBody.error | Select-Object -ExpandProperty message -ErrorAction Ignore
                    if($null -ne $errorCode){
                        $param = @{
                            Message = $errorCode;
                            Verbose = $Verbose;
                        }
                        Write-Verbose @param
                    }
                    if($null -ne $errorMessage){
                        $param = @{
                            Message = $errorMessage;
                            Verbose = $Verbose;
                        }
                        Write-Verbose @param
                    }
                }
                elseif($null -ne ($responseBody.psobject.properties.Item('message'))){
                    $errorCode = $responseBody | Select-Object -ExpandProperty code -ErrorAction Ignore
                    $errorMessage = $responseBody | Select-Object -ExpandProperty message -ErrorAction Ignore
                    if($null -ne $errorCode){
                        $param = @{
                            Message = $errorCode;
                            Verbose = $Verbose;
                        }
                        Write-Verbose @param
                    }
                    if($null -ne $errorMessage){
                        $param = @{
                            Message = $errorMessage;
                            Verbose = $Verbose;
                        }
                        Write-Verbose @param
                    }
                }
            }
            catch{
                #Write detailed error message
                $param = @{
                    Message = ($script:messages.DetailedErrorMessage -f $responseBody);
                    Verbose = $Verbose;
                }
                Write-Verbose @param
            }
        }
        else{
            #Unable to get detailed error message
            $param = @{
                Message = $script:messages.UnableToGetDetailedError;
                Verbose = $Verbose;
            }
            Write-Verbose @param
        }
    }
    catch{
        #Writes detailed error message
        $param = @{
            Message = $script:messages.UnableToProcessErrorMessage;
            Verbose = $Verbose;
        }
        Write-Verbose @param
        #Write detailed error message
        $param = @{
            Message = $_;
            Debug = $Debug;
        }
        Write-Debug @param
    }
}
