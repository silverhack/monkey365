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

Function Write-File {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Write-File
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Log stream")]
        [System.Management.Automation.InformationRecord]$Log,

        [Parameter(Mandatory=$True, HelpMessage="Configuration file")]
        [Object]$Configuration
    )
    Process{
        $formattedMessage = $Log | Get-FormattedMessage
        #Check if file exists
        If((Test-Path -Path $Configuration.Filename) -and $null -ne $formattedMessage){
            $random = Get-Random -Minimum 10 -Maximum 100000
            $MutexName = ('MonkeyLogMutex{0}' -f $random)
            $locked = $false
            $mutex = [System.Threading.Mutex]::new($false,$MutexName)
            Try{
                #$locked = $mutex.WaitOne([System.Threading.Timeout]::Infinite,$false)
                $locked = $mutex.WaitOne(100,$false)
                If($locked) {
                    $stream  = [System.IO.StreamWriter]::new($Configuration.Filename, $true)  # $true for append data
                    $stream.WriteLine($formattedMessage);
                    [void]$stream.Dispose();
                }
            }
            Catch [System.Threading.AbandonedMutexException]{
                $locked = $True
                $p = @{
                    MessageData = $_;
                    Tags = @('WriteFileErrorAbandonedMutexException');
                    logLevel = 'Error';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Error @p
            }
            Catch [System.IO.IOException]{
                #Send lost messages to Verbose
                $p = @{
                    MessageData = $formattedMessage;
                    Tags = @('WriteFileIOException');
                    logLevel = 'Debug';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Verbose @p
                #Write error message
                $p = @{
                    MessageData = $_;
                    Tags = @('WriteFileIOException');
                    logLevel = 'Error';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Error @p
            }
            Catch{
                $p = @{
                    MessageData = $_;
                    Tags = @('WriteFileError');
                    logLevel = 'Error';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Error @p
            }
            Finally{
                If($null -ne $mutex){
                    If($locked){
                        [void]$mutex.ReleaseMutex()
                    }
                    $mutex.Dispose()
                }
            }
        }
    }
}