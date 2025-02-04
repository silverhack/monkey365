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


Function Get-MonkeyBackgroundJob{
    <#
        .SYNOPSIS
		Get status from background jobs

        .DESCRIPTION
		Get status from background jobs

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyBackgroundJob
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
            [Parameter(HelpMessage="Background Job")]
            [object]
            $jobObject,

            [Parameter(HelpMessage="Background Job")]
            [Int]
            $WaitSeconds = 10
    )
    Begin{
        $jobs=$true
        $O365JobResults   = $null
        $errorMessage = $null
        $start_time  = Get-Date
        $watchdog    = 25 #seconds
    }
    Process{
        While ($jobs){
            Switch ($jobObject.State){
                {$_ -eq 'Running'} {
                    $msg = @{
                        MessageData = ($message.O365JobStatus -f $jobObject.Name);
                        logLevel = 'debug';
                        Tags = @('BackgroundJobStatus');
                        Verbose = $O365Object.VerboseOptions.verbose;
                        Debug = $O365Object.VerboseOptions.debug;
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                    }
                    Write-Debug @msg
                }
                {$_ -eq 'Completed'} {
                    $msg = @{
                        MessageData = ($message.O365JobCompleted -f $jobObject.Name);
                        logLevel = 'debug';
                        Tags = @('BackgroundJobStatus');
                        Verbose = $O365Object.VerboseOptions.verbose;
                        Debug = $O365Object.VerboseOptions.debug;
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                    }
                    Write-Debug @msg
                    if ($jobObject.ChildJobs[0].Error) {
                        #Store error message in $errorMessage
                        $errorMessage = $jobObject.ChildJobs[0].Error | Out-String
                        $msg = @{
                            MessageData = ($message.O365JobCompletedWithError -f $jobObject.Name);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'debug';
                            Tags = @('BackgroundJobStatus');
                            Verbose = $O365Object.VerboseOptions.verbose;
                            Debug = $O365Object.VerboseOptions.debug;
                        }
                        Write-Debug @msg
                        #Change message
                        $msg.MessageData = ($message.O365JobError -f $errorMessage)
                        Write-Debug @msg
                    }
                    else{
                        #Get job result and store in $jobResults
                        $O365JobResults = Receive-Job $jobObject.Name
                        $msg = @{
                            MessageData = ($message.O365JobCompletedWithoutError -f $jobObject.Name);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'debug';
                            Tags = @('BackgroundJobStatus');
                            Verbose = $O365Object.VerboseOptions.verbose;
                            Debug = $O365Object.VerboseOptions.debug;
                        }
                        Write-Debug @msg
                    }
                    #Remove the job
                    Remove-Job $jobObject.Name
                    $jobs = $false
                }
                {$_ -eq 'Failed'} {
                    $failReason = $jobObject.ChildJobs[0].JobStateInfo.Reason.Message
                    $msg = @{
                        MessageData = ($message.O365JobFailed -f $jobObject.Name);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        Tags = @('BackgroundJobStatus');
                        Verbose = $O365Object.VerboseOptions.verbose;
                        Debug = $O365Object.VerboseOptions.debug;
                    }
                    Write-Debug @msg
                    #Change message
                    $msg.MessageData = ($message.O365JobFailedReason -f $failReason)
                    Write-Debug @msg
                    #Remove the job
                    Remove-Job $jobObject.Name
                    $jobs = $false
                }
            }
            #Wait seconds. Default 10 seconds
            Start-Sleep -Seconds $WaitSeconds
            $current = Get-Date
            $time_span = $current - $start_time
            if ($time_span.TotalSeconds -gt $watchdog) {
                $msg = @{
                    MessageData = ("TIMEOUT on job {0}" -f $jobObject.Name);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Tags = @('BackgroundJobStatus');
                    Verbose = $O365Object.VerboseOptions.verbose;
                    Debug = $O365Object.VerboseOptions.debug;
                }
                Write-Verbose @msg
                Stop-Job $jobObject
                break
            }
        }
    }
    End{
        if($null -ne $O365JobResults){
            return $O365JobResults
        }
    }
}


