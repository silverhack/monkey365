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

Function Watch-MonkeyJob{
    <#
        .SYNOPSIS
            Get the results of an asynchronous pipeline.
        .DESCRIPTION
            Get the results of an asynchronous pipeline
        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyJob
            Version     : 1.0

            Since it is unknown what exists in the results stream of the job, this function will not have a standard return type.

        .LINK
            https://github.com/silverhack/monkey365
        .PARAMETER Jobs
            An array object, typically returned by 'Invoke-MonkeyJob' Function.
        .PARAMETER BatchSize
            An integer object, used to limit the number of jobs that are to be Queued
        .PARAMETER TimeOut
            An integer object, Timeout before a thread stops trying to gather the information
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

        [Parameter(Mandatory=$false, HelpMessage="Timeout before a thread stops trying to gather the information")]
        [ValidateRange(1,65535)]
        [int32]$Timeout = 10,

        [Parameter(Mandatory=$false, HelpMessage="Used to count jobs")]
        [ref]$Jobscollected
    )
    #Set var
    [int]$current_tasks = 0
    if($PSBoundParameters.ContainsKey('Timeout') -and $PSBoundParameters['TimeOut']){
        #TimeOut is in Milliseconds
        [int]$Timeout = $PSBoundParameters['TimeOut'] * 1000
    }
    else{
        #TimeOut is in Milliseconds
        [int]$Timeout = 10 * 1000
    }
    Do{
        #return if all jobs are completed
        if((@($Jobs| Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Running})).Count -eq 0){
            Write-Information $script:messages.CompletedJobs
            Return
        }
        #If there are no completed jobs, wait for at least one using Eventing WaitAll, simply looping to check if jobs are completed will consume resources
        if((@($Jobs| Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Running})).Count -gt 0){
            #Limit the waitAll on first 10 Tasks
            [array]$MonkeyJobsInProgress = @($Jobs | Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Running} | Select-Object -ExpandProperty Task -First 10)
            if($null -ne $MonkeyJobsInProgress -and @($MonkeyJobsInProgress).Count -gt 0){
                try{
                    While (-not [System.Threading.Tasks.Task]::WaitAll($MonkeyJobsInProgress, $Timeout)) {
                        Write-Verbose $script:messages.WaitJobCompletion
                    }
                }
                catch{
                    #Task Error
                    Write-Error $_
                }
            }
        }
        #Collect All jobs that are completed, it could be greater than the Batchsize, collect them anyway as they are completed
        #https://jeremybytes.blogspot.com/2015/01/task-continuations-checking-isfaulted.html
        $completedJobs = $Jobs| Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Completed}
        if($completedJobs){
            foreach($MonkeyJob in @($completedJobs)){
                if($MonkeyJob.Task.IsCompleted){
                    #Increment the Collection counters
				    $current_tasks++;$Jobscollected.value++
                }
            }
        }

    }until($current_tasks -ge $BatchSize)
}
