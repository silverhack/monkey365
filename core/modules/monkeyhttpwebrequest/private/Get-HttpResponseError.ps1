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
# See the License for the specIfic language governing permissions and
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
        If($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
            $VerbosePreference = 'Continue'
        }
        #Get url and status code
        $url = $ErrorResponse.RequestMessage.RequestUri
        $StatusCode = ($ErrorResponse.StatusCode.value__).ToString().Trim();
        $Reason = $ErrorResponse.ReasonPhrase
        If($null -ne $Url){
            $p = @{
                Message = ($script:messages.UnableToProcessUrl -f $Url);
            }
            Write-Verbose @p
        }
        #Write error message
        $p = @{
            Message = ("[{0}]: {1}" -f $StatusCode, $Reason);
        }
        Write-Verbose @p
        #Get response message
        $rawData = $ErrorResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        If($null -eq $ErrorResponse.Content.Headers.ContentType){
            $contentType = 'application/json'
        }
        Else{
            $contentType = $ErrorResponse.Content.Headers.ContentType.MediaType
        }
        $responseBody = Convert-RawData -RawObject $rawData -ContentType $contentType
        If($null -ne $responseBody){
            try{
                If($null -ne ($responseBody.psobject.properties.Item('odata.error'))){
                    $errorCode = $responseBody.'odata.error'.code
                    $errorMessage = $responseBody.'odata.error'.message.value
                    If($null -ne $errorCode){
                        $p = @{
                            Message = $errorCode;
                        }
                        Write-Verbose @p
                    }
                    If($null -ne $errorMessage){
                        $p = @{
                            Message = $errorMessage;
                        }
                        Write-Verbose @p
                    }
                }
                ElseIf($null -ne ($responseBody.psobject.properties.Item('error_description'))){
                    $p = @{
                        Message = $responseBody.error_description;
                    }
                    Write-Verbose @p
                }
                ElseIf($null -ne ($responseBody.psobject.properties.Item('error'))){
                    $errorCode = $responseBody.error | Select-Object -ExpandProperty code -ErrorAction Ignore
                    $errorMessage = $responseBody.error | Select-Object -ExpandProperty message -ErrorAction Ignore
                    If($null -ne $errorCode){
                        $p = @{
                            Message = $errorCode;
                        }
                        Write-Verbose @p
                    }
                    If($null -ne $errorMessage){
                        $p = @{
                            Message = $errorMessage;
                        }
                        Write-Verbose @p
                    }
                }
                ElseIf($null -ne ($responseBody.psobject.properties.Item('message'))){
                    $errorCode = $responseBody | Select-Object -ExpandProperty code -ErrorAction Ignore
                    $errorMessage = $responseBody | Select-Object -ExpandProperty message -ErrorAction Ignore
                    If($null -ne $errorCode){
                        $p = @{
                            Message = $errorCode;
                        }
                        Write-Verbose @p
                    }
                    If($null -ne $errorMessage){
                        $p = @{
                            Message = $errorMessage;
                        }
                        Write-Verbose @p
                    }
                }
            }
            catch{
                #Write detailed error message
                $p = @{
                    Message = ($script:messages.DetailedErrorMessage -f $responseBody);
                }
                Write-Verbose @p
            }
        }
        Else{
            #Unable to get detailed error message
            $p = @{
                Message = $script:messages.UnableToGetDetailedError;
            }
            Write-Verbose @p
        }
    }
    catch{
        #Writes detailed error message
        $p = @{
            Message = $script:messages.UnableToProcessErrorMessage;
        }
        Write-Verbose @p
        #Write detailed error message
        $p = @{
            Message = $_;
        }
        Write-Verbose @p
    }
}

