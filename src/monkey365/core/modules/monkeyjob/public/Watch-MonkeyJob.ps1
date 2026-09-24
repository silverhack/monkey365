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

Function Watch-MonkeyJob{
    <#
        .SYNOPSIS
            Get the results of an asynchronous pipeline.
        .DESCRIPTION
            Get the results of an asynchronous pipeline
        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Watch-MonkeyJob
            Version     : 1.0

            Since it is unknown what exists in the results stream of the job, this function will not have a standard return type.

        .LINK
            https://github.com/silverhack/monkey365
        .PARAMETER Jobs
            An array object, typically returned by 'Invoke-MonkeyJob' Function.
        .PARAMETER BatchSize
            An integer object, used to limit the number of jobs that are to be Queued
        .PARAMETER TimeOut
            An integer object, Timeout before a thread stops Trying to gather the information
        .PARAMETER Jobscollected
            An integer object [referenced] which is used to count jobs.
        .PARAMETER JobsErrors
            An array object [referenced] which is used to store job errors.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, position=0, HelpMessage="Jobs")]
        [Object]$Jobs,

        [Parameter(Mandatory=$false, HelpMessage="BatchSize")]
        [int]$BatchSize = 80,

        [Parameter(Mandatory=$false, HelpMessage="Timeout before a thread stops Trying to gather the information")]
        [ValidateRange(1,65535)]
        [int32]$Timeout = 10,

        [Parameter(Mandatory=$false, HelpMessage="Used to count jobs")]
        [ref]$Jobscollected
    )
    #Set var
    [int]$current_tasks = 0
    # Track processed jobs to avoid double counting
    $processedJobIds = [System.Collections.Generic.HashSet[string]]::new()
    If($PSBoundParameters.ContainsKey('Timeout') -and $PSBoundParameters['TimeOut']){
        #TimeOut is in Milliseconds
        [int]$Timeout = $PSBoundParameters['TimeOut'] * 1000
    }
    Else{
        #TimeOut is in Milliseconds
        [int]$Timeout = 10 * 1000
    }
    Do{
        # Return if all jobs are completed, failed, or stopped
        $activeJobs = @($Jobs).Where({$_.Job.State -eq [System.Management.Automation.JobState]::Running})
        if ($activeJobs.Count -eq 0) {
            Write-Verbose $script:messages.CompletedJobs
            return
        }
        # Wait for up to 10 running tasks
        if ($activeJobs.Count -gt 0) {
            [array]$MonkeyJobsInProgress = $activeJobs | Select-Object -ExpandProperty Task -First 10
            if ($null -ne $MonkeyJobsInProgress -and @($MonkeyJobsInProgress).Count -gt 0) {
                try {
                    while (-not [System.Threading.Tasks.Task]::WaitAll($MonkeyJobsInProgress, $Timeout)) {
                        Write-Verbose $script:messages.WaitJobCompletion
                    }
                } catch {
                    Write-Error $_
                }
            }
        }
        # Collect jobs that are completed, failed, or stopped
        $finishedJobs = @($Jobs).Where({
            ($_.Job.State -eq [System.Management.Automation.JobState]::Completed -or
             $_.Job.State -eq [System.Management.Automation.JobState]::Failed -or
             $_.Job.State -eq [System.Management.Automation.JobState]::Stopped)
        })
        foreach ($MonkeyJob in $finishedJobs) {
            $jobId = $MonkeyJob.Job.Id.ToString()
            if (-not $processedJobIds.Contains($jobId) -and $MonkeyJob.Task.IsCompleted) {
                $null = $processedJobIds.Add($jobId)
                $current_tasks++
                $Jobscollected.value++
                # Optionally, handle/report failed jobs here
                if ($MonkeyJob.Job.State -eq [System.Management.Automation.JobState]::Failed) {
                    Write-Warning ($script:messages.JobFailedMessage -f $jobId)
                }
            }
        }
    } until ($current_tasks -ge $BatchSize)
}

