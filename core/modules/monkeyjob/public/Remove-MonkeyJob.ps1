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

        [Parameter(Mandatory=$false, HelpMessage="Job RunspacePoolId")]
        [Switch]$Force,

        [Parameter(Mandatory=$false, HelpMessage="Dispose Job")]
        [Switch]$Dispose,

        [Parameter(Mandatory=$false, HelpMessage="Keep RunspacePool")]
        [Switch]$KeepRunspacePool

    )
    Begin{
        $queries = [System.Collections.Generic.List[ScriptBlock]]::new()
    }
    Process{
        $psn = $PSCmdlet.ParameterSetName
        $items = $PSBoundParameters[$psn]
        foreach($item in $items){
            if($PSCmdlet.ParameterSetName -eq 'Job'){
                $rule = ('$_.{0} -eq "{1}"' -f "Id",$item.Id)
            }
            else{
                $rule = ('$_.{0} -eq "{1}"' -f $psn,$item)
            }
            $sb = [ScriptBlock]::Create($rule)
            [void]$queries.Add($sb)
        }
    }
    End{
        foreach($query in $queries){
            $MonkeyJob = $MonkeyJobs | Where-Object $query -ErrorAction Ignore;
            if($null -ne $MonkeyJob){
                if($PSBoundParameters.ContainsKey('Force')){
                    [void]$MonkeyJob.Job.InnerJob.Stop()
                }
                #Clean MonkeyJob object
                #$MonkeyJob.Job.InnerJob.Stop();
                $MonkeyJob.Job.InnerJob.Dispose();
                if(!$PSBoundParameters.ContainsKey('KeepRunspacePool')){
                    #$MonkeyJob.Job.InnerJob.RunspacePool.Close();
                    $MonkeyJob.Job.InnerJob.RunspacePool.Dispose();
                }
                $MonkeyJob.Job.StopJob();
                $MonkeyJob.Job.Dispose();
                $MonkeyJob.Task.Dispose();
                $MonkeyJob.Task = $null;
                [void]$MonkeyJobs.Remove($MonkeyJob)
                #Perform garbage collection
                [gc]::Collect()
            }
        }
    }
}
