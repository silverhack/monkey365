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

Function Invoke-MonkeyJob{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyJob
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding(DefaultParameterSetName='ScriptBlock')]
    Param (
        [Parameter(Mandatory=$True,position=0,ParameterSetName='ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$True, ParameterSetName = 'Command')]
        [String]$Command,

        [Parameter(Mandatory=$false, HelpMessage="arguments")]
        [Object]$Arguments,

        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        $InputObject,

        [Parameter(HelpMessage="Variables to import into runspace")]
        [Object]$ImportVariables,

        [Parameter(HelpMessage="runspace")]
        [System.Management.Automation.Runspaces.RunspacePool]$Runspacepool,

        [Parameter(HelpMessage="modules to import into sessionState")]
        [Object]$ImportModules,

        [Parameter(HelpMessage="commands to import into sessionState")]
        [Object]$ImportCommands,

        [Parameter(HelpMessage="commands as AST to import into sessionState")]
        [Object]$ImportCommandAst,

        [Parameter(HelpMessage="Startup scripts (*ps1 files) to execute")]
        [System.Object[]]$StartUpScripts,

        [Parameter(HelpMessage="Minimum number of runspaces")]
        [ValidateRange(1,65535)]
        [int32]$MinThrottle = 1,

        [Parameter(HelpMessage="Maximum number of runspaces")]
        [ValidateRange(1,65535)]
        [int32]$Throttle = 2,

        [Parameter(HelpMessage="BatchSize")]
        [int32]$BatchSize = 80,

        [Parameter(HelpMessage="Pause between batchs in milliseconds")]
        [int32]$BatchSleep = 0,

        [Parameter(HelpMessage="Timeout before a thread stops trying to gather the information")]
        [ValidateRange(1,65535)]
        [int32]$Timeout = 10,

        [Parameter(HelpMessage="Increase Sleep Timer in seconds between child objects")]
        [ValidateRange(1,65535)]
        [int32]$SleepTimer = 5,

        [Parameter(HelpMessage="Increase Sleep Timer in seconds between child objects")]
        [ValidateRange(1,65535)]
        [int32]$MaxQueue = 10,

        [Parameter(HelpMessage="ApartmentState of the thread")]
        [ValidateSet("STA","MTA")]
        [String]$ApartmentState = "STA",

        [Parameter(HelpMessage="Reuse runspacePool")]
        [Switch]$ReuseRunspacePool,

        [Parameter(Mandatory=$False, HelpMessage='ThrowOnRunspaceOpenError')]
        [Switch]$ThrowOnRunspaceOpenError
    )
    Begin{
        if($PSBoundParameters.ContainsKey('ReuseRunspacePool') -and $PSBoundParameters['ReuseRunspacePool'].IsPresent){
            $reuseRSP = $True
        }
        else{
            $reuseRSP = $false
        }
        if (-not $PSBoundParameters.ContainsKey('ThrowOnRunspaceOpenError')) {
            $ThrowOnRunspaceOpenError = $False
        }
        if( -not $PSBoundParameters.ContainsKey('MaxQueue') ) {
            $MaxQueue = 3 * $MaxQueue
        }
        else {
            $MaxQueue = $MaxQueue
        }
        #Create new runspace or reuse existing
        if (-not $PSBoundParameters.ContainsKey('Runspacepool')) {
            #Create a new runspacePool
            $localparams = @{
                ImportVariables = $ImportVariables;
                ImportModules = $ImportModules;
                ImportCommands = $ImportCommands;
                ImportCommandsAst = $ImportCommandAst;
                ApartmentState = $ApartmentState;
                MinThrottle = $MinThrottle;
                Throttle = $Throttle;
                StartUpScripts = $StartUpScripts;
                ThrowOnRunspaceOpenError = $ThrowOnRunspaceOpenError;
            }
            #Get runspace pool
            $Runspacepool = New-RunspacePool @localparams
            if($null -ne $Runspacepool -and $Runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                #Open runspace
                Write-Verbose $script:messages.OpenRunspaceMessage
                $Runspacepool.Open()
                #Add RunspacePool to array
                if($null -ne (Get-Variable -Name MonkeyRSP -ErrorAction Ignore)){
                    [void]$MonkeyRSP.Add($Runspacepool);
                }
            }
        }
        else{
            if($Runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::BeforeOpen){
                #Open runspace
                Write-Verbose $script:messages.OpenRunspaceMessage
                $Runspacepool.Open()
            }
        }
        #Set Monkeyjobs variable
        if($null -eq (Get-Variable -Name MonkeyJobs -ErrorAction Ignore)){
            $MonkeyJobs = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        }
        #Set timers, vars
        $Timer = [system.diagnostics.stopwatch]::StartNew()
        $SubTimer = [system.diagnostics.stopwatch]::StartNew()
        [int]$script:jobsCollected = 0
        if($PSBoundParameters.ContainsKey('Timeout') -and $PSBoundParameters['TimeOut']){
            #TimeOut is in Milliseconds
            [int]$Timeout = $PSBoundParameters['TimeOut'] * 1000
        }
        else{
            #TimeOut is in Milliseconds
            [int]$Timeout = 10 * 1000
        }
    }
    Process{
        if($null -ne $Runspacepool -and $Runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::Opened){
            #Get scriptblock if any
            $param = @{
                RunspacePool = $Runspacepool;
                InputObject = $InputObject;
                Arguments = $Arguments;
            }
            if($PSCmdlet.ParameterSetName -eq 'ScriptBlock'){
                if($InputObject){
                    $sb = Set-ScriptBlock -ScriptBlock $ScriptBlock -AddInputObject
                }
                else{
                    $sb = Set-ScriptBlock -ScriptBlock $ScriptBlock
                }
                [void]$param.Add('ScriptBlock',$sb)
            }
            elseif($PSCmdlet.ParameterSetName -eq 'Command'){
                [void]$param.Add('Command',$Command)
            }
            #Get new PowerShell Object
            $Pipeline = New-PowerShellObject @param
            if($Pipeline){
                #Set Job name
                $jobName = ("MonkeyTask{0}" -f (Get-Random -Maximum 1000 -Minimum 1));
                #Create a new Job
                $Job = [MonkeyJob]::new($Pipeline,$jobName);
                #Get new MonkeyJob object
                $newJob = New-MonkeyJobObject
                if($newJob -and $null -ne $Job){
                    #Populate job
                    $newJob.RunspacePoolId = $Pipeline.RunspacePool.InstanceId;
                    $newJob.Name = $jobName;
                    $newJob.Job = $Job;
                    if($PSCmdlet.ParameterSetName -eq 'ScriptBlock'){
                        $newJob.Command = $scriptblock.ToString();
                    }
                    elseif($PSCmdlet.ParameterSetName -eq 'Command'){
                        $p = @{
                            Command = $Command;
                            InputObject = $InputObject;
                            Arguments = $Arguments;
                        }
                        $cmd = Format-Command @p
                        if($cmd){
                            $newJob.Command = $cmd.ToString();
                        }
                    }
                    #Add to list
                    [void]$MonkeyJobs.Add($newJob);
                }
            }
        }
        else{
            if($Runspacepool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspaceState]::Opened){
                Write-Error ($script:messages.RunspaceError)
                return
            }
            else{
                Write-Error ($script:messages.UnknownError)
                return
            }
        }
    }
    End{
        try{
            for($NumJob = 0 ; $NumJob -lt $MonkeyJobs.Count; $NumJob++){
                $MonkeyJob = $MonkeyJobs.Item($NumJob)
                #Start Job
                $MonkeyJob.Task = $MonkeyJob.Job.StartTask();
                #Check if maxQueue
                if($NumJob -ge $MaxQueue){
                    Write-Verbose ($script:messages.TimeSpentInvokeBatchMessage -f ($NumJob / $BatchSize), $SubTimer.Elapsed.ToString())
                    $SubTimer.Reset();$SubTimer.Start()
                    $p = @{
                        Jobs = $MonkeyJobs;
                        BatchSize = $BatchSize;
                        Timeout = $Timeout;
                        Jobscollected = ([ref]$Script:jobsCollected);
                    }
                    Watch-MonkeyJob @p
                    $SubTimer.Stop()
                    Write-Verbose ($script:messages.TimeSpentCollectBatchMessage -f ($NumJob / $BatchSize), $SubTimer.Elapsed.ToString())
                    $SubTimer.Reset()
                    if($BatchSleep){
                        Write-Verbose ($script:messages.SleepMessage -f $BatchSleep)
                        Start-Sleep -Milliseconds $BatchSleep
                    }
                    $SubTimer.Start()
                    $MaxQueue += $BatchSize
                }
            }
            #All jobs are invoked at this time, just collect all of them
            Write-Verbose "Invoked all Jobs, Collecting the last jobs that are running"
            #Collect all jobs
            While ((@($MonkeyJobs | Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Running})).count -gt 0){
                #We want to collect all the Jobs, so just double the BatchSize
			    $BS = (@($MonkeyJobs | Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Running})).count * 2
                $p = @{
                    Jobs = $MonkeyJobs;
                    BatchSize = $BS;
                    Timeout = $Timeout;
                    Jobscollected = ([ref]$Script:jobsCollected);
                }
                Watch-MonkeyJob @p
            }
        }
        catch{
            Write-Error ("MonkeyJob Error: {0}" -f $_)
        }
        finally{
            #Get Data
            $completedJobs = $MonkeyJobs | Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Completed}
            #Receive jobs
            $completedJobs | Receive-MonkeyJob
            #Clean objects
            if($MonkeyJobs.Count -gt 0){
                Write-Verbose ($script:messages.TerminateJobMessage -f $MonkeyJobs.Count)
                Get-MonkeyJob | Remove-MonkeyJob -KeepRunspacePool:$reuseRSP
            }
            #Stop timer
            If($Timer.Isrunning){
			    Write-Verbose "Exiting script"
                Write-Verbose ("Jobs Collected: {0}" -f $script:jobsCollected)
                Write-Verbose ("Time took to Invoke and Complete the Jobs : {0}" -f $Timer.Elapsed.ToString())
			    $Timer.Stop()
            }
            #Dispose RunspacePool
            if(!$reuseRSP -and $null -ne $Runspacepool -and $Runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                Write-Verbose $script:messages.CloseRunspaceMessage
                #https://github.com/PowerShell/PowerShell/issues/5746
                #$Runspacepool.Close()
                $Runspacepool.Dispose()
            }
            #collect garbage
            #[gc]::Collect()
            [System.GC]::GetTotalMemory($true) | out-null
        }
    }
}