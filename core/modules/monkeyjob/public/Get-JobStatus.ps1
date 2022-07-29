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

Function Get-JobStatus{
    <#
        .SYNOPSIS
            Get the results of an asynchronous pipeline.
        .DESCRIPTION
            Get the results of an asynchronous pipeline
        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-RunspacePool
            Version     : 1.0

            Since it is unknown what exists in the results stream of the job, this function will not have a standard return type.

        .LINK
            https://github.com/silverhack/monkey365
        .PARAMETER Jobs
            An array object, typically returned by 'Invoke-MonkeyJob' Function.
        .PARAMETER BSize
            An integer object, used to limit the number of jobs that are to be Queued
        .PARAMETER Jobscollected
            An integer object [referenced] which is used to count jobs.
        .PARAMETER JobsErrors
            An array object [referenced] which is used to store job errors.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(HelpMessage="Jobs")]
        [Object]$Jobs,

        [Parameter(HelpMessage="Jobs")]
        [int]$BSize,

        [Parameter(HelpMessage="Timeout before a thread stops trying to gather the information")]
        [ValidateRange(1,65535)]
        [int32]$Timeout,

        [Parameter(HelpMessage="Jobs")]
        [ref]$Jobscollected,

        [Parameter(HelpMessage="Jobs Errors")]
        [ref]$JobsErrors

    )
    [int]$current_tasks = 0
    $JobsInProgress = @()
    if (-not $PSBoundParameters.ContainsKey('Timeout')) {
        #TimeOut is in Milliseconds
        [int]$Timeout = 300 * 1000
    }
    else{
        #TimeOut is in Milliseconds
        [int]$Timeout = $PSBoundParameters.TimeOut * 1000
    }
    Do{
        #return if all jobs are completed
        if((@($Jobs.Values| Where-Object {$Null -ne $_.Handle})).Count -eq 0){
            Write-Information $script:messages.CompletedJobs
            Return
        }
        #If there are no completed jobs, wait for atleast one using Eventing Wait, simply looping to check if jobs are completed will consume resources
        if((@($Jobs.values | Where-Object{$Null -ne $_.Handle -AND $_.Handle.Iscompleted -eq $true})).count -eq 0){
            #If 80% of the Jobs in batch are completed, Go back and Invoke more jobs, this is avoid waiting on the batch if there are couple or few jobs that are long running
            if((($current_tasks / $BSize)*100) -gt 80){
                Return
            }
            #WaitAny has 64 Handle limitation. limit the wait on first 60 handles
            [array]$JobsInProgress = @($Jobs.Values.GetEnumerator() | Where-Object{($Null -ne $_.Thread) -and $_.Thread.InvocationStateInfo.State -eq [System.Management.Automation.PSInvocationState]::Running} | Select-Object -First 60)
            $CompletedHandles = $Null
            #Waittime for the job to complete, if it didnt, loop back
            #If the User has pressed Ctrl+c inbetween the wait, the script will terminate and Outer finally block is executed
			#WaitAny retuns the Index of the completed Job
            if($null -ne $JobsInProgress -and [bool]($JobsInProgress.PSobject.Properties.name -match "Count") -and $JobsInProgress.Count -gt 0){
                do{
					Write-Verbose "Waiting for job completion" #$script:messages.WaitJobCompletion
                    $CompletedHandles = [System.Threading.WaitHandle]::WaitAny($JobsInProgress.Handle.AsyncWaitHandle,$Timeout)
                }While($CompletedHandles -eq [System.Threading.WaitHandle]::WaitTimeout)
            }
        }
        #Collect All jobs that are completed, it could be greater than the Batchsize, collect them anyway as they are completed
        ForEach ($Job in $($Jobs.Values.GetEnumerator() | Where-Object {($Null -ne $_.Handle) -and $_.Handle.IsCompleted -eq $True})){
            try{
                #Collect the result of the completed Job and send it to the next pipeline or Host
				$Job.Thread.EndInvoke($Job.Handle)
				#Increment the Collection counters
				$current_tasks++;$Jobscollected.value++
            }Catch{
				Write-Error ($script:messages.ErrorOnThreadEndInvoke -f $_)
				Write-Error ($script:messages.DetailedEndInvokeErrorMessage -f $Job.FunctionName, $Job.Id)
                $JobError = [ordered]@{
                    Id = $job.Id;
                    FunctionName = $Job.FunctionName;
                    JobObject = $Job;
                    ScriptBlockInfo = $Job.ScriptBlockInfo;
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    ErrorStr = $_.Exception.Message;
                    Exception = $_;
                }
                $JobsErrors.Value += New-Object PSObject -Property $JobError
            }finally{
				if ($Job.Thread.HadErrors) {
                    foreach($record in $Job.Thread.Streams.Error.ReadAll()){
                        $JobError = [ordered]@{
                            Id = $job.Id;
                            FunctionName = $Job.FunctionName;
                            JobObject = $Job;
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            ErrorStr = $record.Exception.Message;
                            Exception = $record;
                        }
                        #Add exception to ref
                        #$psError = New-Object PSObject -Property $JobError
                        $JobsErrors.Value += New-Object PSObject -Property $JobError
					}
				}
				$Job.Thread.Dispose()
				$Job.Thread = $Null
				$Job.Handle = $Null
            }
        }
    }until($current_tasks -ge $BSize)
}
