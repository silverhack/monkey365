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

Function Remove-MonkeyJob{
    <#
        .SYNOPSIS
            Remove MonkeyJob
        .DESCRIPTION
            Remove an automation job
        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Remove-MonkeyJob
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
        .PARAMETER Job
            The job object to remove
        .PARAMETER Name
            The name of the jobs to remove
        .PARAMETER Id
            The Id of the jobs to remove
        .PARAMETER InstanceID
            The runspace Id of the jobs to remove
        .PARAMETER Force
            Force a running job to stop prior to being removed
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding(DefaultParameterSetName='Job')]
    Param
    (
        [Parameter(Mandatory=$true, ParameterSetName='Job', position=0, ValueFromPipeline=$true, HelpMessage="Job to remove")]
        [Alias('InputObject')]
        [Object[]]$Job,

        [Parameter(Mandatory=$true, ParameterSetName='Name', HelpMessage="Job Name")]
        [String[]]$Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id', HelpMessage="Job Id")]
        [Int[]]$Id,

        [Parameter(Mandatory=$true, ParameterSetName='RunspacePoolId', HelpMessage="Job RunspacePoolId")]
        [System.Guid[]]$RunspacePoolId,

        [Parameter(Mandatory=$false, HelpMessage="Force remove")]
        [Switch]$Force,

        [Parameter(Mandatory=$false, HelpMessage="Keep RunspacePool")]
        [Switch]$KeepRunspacePool

    )
    Begin{
        $queries = [System.Collections.Generic.List[System.Management.Automation.ScriptBlock]]::new()
    }
    Process{
        $psn = $PSCmdlet.ParameterSetName
        $items = $PSBoundParameters[$psn]
        ForEach($item in @($items)){
            Try{
                If($PSCmdlet.ParameterSetName -eq 'Job'){
                    $rule = ('$_.{0} -eq "{1}"' -f "Id",$item.Id)
                }
                Else{
                    $rule = ('$_.{0} -eq "{1}"' -f $psn,$item)
                }
                [void]$queries.Add([System.Management.Automation.ScriptBlock]::Create($rule))
            }
            Catch{
                Write-Error $_.Exception
            }
        }
    }
    End{
        # Remove jobs if terminated or as requested
        ForEach($query in $queries){
            $_jobs = $MonkeyJobs.Where($query)
            ForEach($MonkeyJob in $_jobs.Where({$null -ne $_})){
                Try {
                    $JobStatus = $MonkeyJob.Job.JobStatus()
                    # Collect job errors if any
                    If($JobStatus.Error.Count -gt 0){
                        ForEach($exception in $JobStatus.Error.GetEnumerator()){
                            $JobError = [PsCustomObject]@{
                                Id = $MonkeyJob.Id
                                callStack = (Get-PSCallStack | Select-Object -First 1)
                                ErrorStr = $exception.Exception.Message
                                Exception = $exception
                            }
                            If($null -ne (Get-Variable -Name MonkeyJobErrors -ErrorAction Ignore)){
                                [void]$MonkeyJobErrors.Add($JobError)
                            }
                        }
                    }
                    # If job is running and force is specified, forcibly stop
                    If($MonkeyJob.Job.State -notmatch 'Completed|Failed|Stopped') {
                        If ($PSBoundParameters.ContainsKey('Force')) {
                            $MonkeyJob.Job.ForceStop()
                            If (-NOT $PSBoundParameters.ContainsKey('KeepRunspacePool')) {
                                $MonkeyJob.Job.DisposeInnerRunspacePool()
                            }
                            #Dispose the job
                            $MonkeyJob.Job.Dispose()
                        }
                        Else{
                            Write-Warning ($script:messages.UnableToRemoveJobDetailed -f $MonkeyJob.Id,"Job is not completed, failed or stopped")
                            return
                        }
                    }
                    Else{
                        Write-Verbose ($script:messages.StoppingJobMessage -f $MonkeyJob.Id,$MonkeyJob.Job.State)
                        $MonkeyJob.Job.StopJob()
                        If (-NOT $PSBoundParameters.ContainsKey('KeepRunspacePool')) {
                            $MonkeyJob.Job.DisposeInnerRunspacePool()
                        }
                        #Dispose the job
                        $MonkeyJob.Job.Dispose()
                    }
                    If($MonkeyJob.Job.State -match 'Completed|Failed|Stopped') {
                        # Dispose task if present and in terminal state
                        If ($null -ne $MonkeyJob.Task -and $MonkeyJob.Task.Status -match 'Canceled|Faulted|RanToCompletion') {
                            $MonkeyJob.Task.Dispose()
                            $MonkeyJob.Task = $null
                        }
                        Else{
                            Write-Warning ($script:messages.UnableToDisposeTask -f $MonkeyJob.Task.Id,$MonkeyJob.Task.Status)
                        }
                        # Remove from collection
                        [void]$MonkeyJobs.Remove($MonkeyJob)
                    }
                    Else{
                        Write-Warning ($script:messages.UnableToRemoveJob -f $MonkeyJob.Id,$MonkeyJob.Job.State, $MonkeyJob.Task.Status)
                        return
                    }
                }
                Catch{
                    Write-Error ("Failed to remove MonkeyJob {0}: {1}" -f $MonkeyJob.Id, $_.Exception.Message)
                }
            }
        }
    }
}

