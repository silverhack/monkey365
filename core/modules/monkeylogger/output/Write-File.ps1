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
        [parameter(ValueFromPipeline = $false,ValueFromPipeLineByPropertyName = $True)]
        [System.Management.Automation.InformationRecord] $Log,

        [parameter(ValueFromPipeline = $false,ValueFromPipeLineByPropertyName = $True)]
        [object] $Configuration
    )
    Begin{
        $shouldPublish = Confirm-Publication -Log $Log -Configuration $Configuration
        if($shouldPublish){
            $formattedMessage = Get-FormattedMessage -Log $Log
        }
        else{
            $formattedMessage = $null
        }
    }
    Process{
        #Check if file exists
        if((Test-Path -Path $Configuration.Filename) -and $null -ne $formattedMessage){
            $random = Get-Random -Minimum 10 -Maximum 100000
            #[bool]$mutexRef = $false
            $MutexName = ('MonkeyLogMutex{0}' -f $random)
            #$mutex = [System.Threading.Mutex]::TryOpenExisting($MutexName,[ref]$mutexRef)
            $locked = $false
            $mutex = [System.Threading.Mutex]::new($false,$MutexName)
            #$locked = $false
            #[void]$mutex.WaitOne()
            try{
                #$locked = $mutex.WaitOne([System.Threading.Timeout]::Infinite,$false)
                $locked = $mutex.WaitOne(100,$false)
                if ($locked) {
                    $stream  = [System.IO.StreamWriter]::new($Configuration.Filename, $true)  # $true for append data
                    $stream.WriteLine($formattedMessage)
                    [void]$stream.Dispose()
                    #[System.IO.File]::AppendAllText($Configuration.Filename,$formattedMessage+([Environment]::NewLine));
                    #[System.Threading.Thread]::Sleep(10);
                }
            }
            catch [System.Threading.AbandonedMutexException]{
                $locked = $True
                <#
                $param = @{
                    MessageData = $_;
                    Tags = @('WriteFileErrorAbandonedMutexException');
                    logLevel = 'Error';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Error @param
                #>
            }
            catch [System.IO.IOException]{
                <#
                #Send lost messages to Debug
                $param = @{
                    MessageData = $formattedMessage;
                    Tags = @('WriteFileIOException');
                    logLevel = 'Debug';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Debug @param
                #>
            }
            catch{
                <#
                $param = @{
                    MessageData = $_;
                    Tags = @('WriteFileError');
                    logLevel = 'Error';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Error @param
                #>
            }
            finally{
                if($null -ne $mutex){
                    if($locked){
                        [void]$mutex.ReleaseMutex()
                    }
                    $mutex.Dispose()
                }
            }
        }
    }
    End{
        #nothing to do here
    }
}

