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

Function Initialize-MonkeyLogger{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-MonkeyLogger
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, HelpMessage="Initial path")]
        [String]$InitialPath
    )
    $loggers = @()
    if($null -eq (Get-Variable -Name O365Object -Scope Script -ErrorAction Ignore)){
        #Create a new O365 object
        New-O365Object
    }
    #Check if write Log
    if($O365Object.WriteLog){
        $fileLogger = $O365Object.internal_config.logging.default.GetEnumerator() | `
                                Where-Object {$_.type -eq "file"} | Select-Object -First 1
        if($null -ne $fileLogger -and $null -ne $fileLogger.configuration.filename){
            $isRoot = [System.IO.Path]::IsPathRooted($fileLogger.configuration.filename)
            if(-NOT $isRoot){
                $log_path = ("{0}/log/{1}" -f $ScriptPath, $fileLogger.configuration.filename)
                $fileLogger.configuration.filename = $log_path
            }
            #Add file logger
            $loggers+=$fileLogger
        }
    }
    #TODO: Add console format log
    #Get additional loggers if any
    if($O365Object.internal_config.logging.loggers){
        $loggers+=$O365Object.internal_config.logging.loggers
    }
    #Start logging
    if($loggers){
        $l_param = @{
            Loggers = $loggers;
            InitialPath = $InitialPath;
            informationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $status = Start-Logger @l_param
    }
    else{
        $l_param = @{
            InitialPath = $InitialPath;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $status = Start-Logger @l_param
    }
    if($status -eq $false){
        $msg = @{
            MessageData = ($message.LoggerError);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('LoggerError');
        }
        Write-Warning @msg
    }
}


