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

Function Get-WebTaskException{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-WebTaskException
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage='Task Object')]
        [Object]$Task
    )
    try{
        $Url = $webResponse = $responseBody = $StatusCode = $null
        $errorMessage = $Task.Exception.Message
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
        #Get Task InnerException
        $task_exception = $Task.Exception.InnerException
        #Get Web Response
        if($null -ne $task_exception.Psobject.Properties.Item('Response')){
            $webResponse = $task_exception.Response
        }
        elseif($null -ne $task_exception.Psobject.Properties.Item('InnerException') -and $null -ne $task_exception.InnerException){
            if($null -ne $task_exception.InnerException.Psobject.Properties.Item('Response')){
                $webResponse = $task_exception.InnerException.Response
            }
        }
        elseif($null -ne $task_exception.Psobject.Properties.Item('InnerExceptions') -and $null -ne $task_exception.InnerExceptions){
            $webResponse = $task_exception.InnerExceptions.Response
        }
        else{
            $webResponse = $null
        }
        if($null -ne $webResponse){
            try{
                $Url = $webResponse.ResponseUri.OriginalString
            }
            catch{
                $Url = $null
            }
            try{
                $StatusCode = ($webResponse.StatusCode.value__ ).ToString().Trim();
            }
            catch{
                $StatusCode = "-1"
            }
            try{
                $errorMessage = $Task.Exception.InnerException.InnerException.Message
            }
            catch{
                $errorMessage = $Task.Exception.Message
            }
        }
        if($null -ne $Url){
            $param = @{
                Message = ($script:messages.UnableToProcessUrl -f $Url);
                Verbose = $Verbose;
            }
            Write-Verbose @param
        }
        #Write error message
        $param = @{
            Message = ("[{0}]: {1}" -f $StatusCode, $errorMessage);
            Verbose = $Verbose;
        }
        Write-Verbose @param
        if($null -ne $webResponse){
            try{
                $responseBody = $null;
                #Get Exception Body Message
                $reader = [System.IO.StreamReader]::new($webResponse.GetResponseStream())
                if($null -ne $reader){
                    $responseBody = $reader.ReadToEndAsync().GetAwaiter().GetResult();
                }
            }
            catch{
                $responseBody = $null
            }
        }
        #Check if valid JSON and writes error message
        if($null -ne $responseBody){
            try{
                $detailed_message = ConvertFrom-Json $responseBody
                if($null -ne ($detailed_message.psobject.properties.Item('odata.error'))){
                    $errorCode = $detailed_message.'odata.error'.code
                    $errorMessage = $detailed_message.'odata.error'.message.value
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
                elseif($null -ne ($detailed_message.psobject.properties.Item('error'))){
                    try{
                        $errorCode = $detailed_message.error.code
                    }
                    catch{
                        $errorCode = $null
                    }
                    try{
                        $errorMessage = $detailed_message.error.message
                    }
                    catch{
                        $errorMessage = $null
                    }
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
                elseif($null -ne ($detailed_message.psobject.properties.Item('error_description'))){
                    try{
                        $error_message = $detailed_message.error
                    }
                    catch{
                        $error_message = $null
                    }
                    try{
                        $errorMessage = $detailed_message.error_description
                    }
                    catch{
                        $errorMessage = $null
                    }
                    if($null -ne $error_message){
                        $param = @{
                            Message = $error_message;
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
                elseif($null -ne ($detailed_message.psobject.properties.Item('message'))){
                    try{
                        $errorCode = $detailed_message.code
                    }
                    catch{
                        $errorCode = $null
                    }
                    try{
                        $errorMessage = $detailed_message.message
                    }
                    catch{
                        $errorMessage = $null
                    }
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
                Verbose = $PSBoundParameters['Verbose'];
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
