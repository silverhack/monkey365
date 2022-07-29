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

    [cmdletbinding(SupportsShouldProcess = $True,DefaultParameterSetName='ScriptBlock')]
    Param (
            [Parameter(Mandatory=$True,position=0,ParameterSetName='ScriptBlock')]
            [System.Management.Automation.ScriptBlock]$ScriptBlock,

            [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
            $InputObject,

            [Parameter(HelpMessage="Variables to import into runspace")]
            [Object]$ImportVariables,

            [Parameter(HelpMessage="Variables to import into runspace")]
            [System.Management.Automation.Runspaces.RunspacePool]$runspacepool,

            [Parameter(HelpMessage="modules to import into sessionState")]
            [Object]$ImportModules,

            [Parameter(HelpMessage="commands to import into sessionState")]
            [Object]$ImportCommands,

            [Parameter(HelpMessage="commands as AST to import into sessionState")]
            [Object]$ImportCommandAst,

            [Parameter(HelpMessage="Startup scripts (*ps1 files) to execute")]
            [System.Object[]]$StartUpScripts,

            [Parameter(HelpMessage="Maximum number of concurrent threads")]
            [ValidateRange(1,65535)]
            [int32]$Throttle = 2,

            [Parameter(HelpMessage="BatchSize")]
            [int32]$BatchSize = 100,

            [Parameter(HelpMessage="Pause between batchs in milliseconds")]
            [int32]$BatchSleep = 0,

            [Parameter(HelpMessage="Timeout before a thread stops trying to gather the information")]
            [ValidateRange(1,65535)]
            [int32]$Timeout = 120,

            [Parameter(HelpMessage="Increase Sleep Timer in seconds between child objects")]
            [ValidateRange(1,65535)]
            [int32]$SleepTimer = 5,

            [Parameter(HelpMessage="Increase Sleep Timer in seconds between child objects")]
            [ValidateRange(1,65535)]
            [int32]$MaxQueue = 10,

            [Parameter(HelpMessage="ApartmentState of the thread")]
            [ValidateSet("STA","MTA")]
            [String]$ApartmentState = "STA",

            [Parameter(HelpMessage="Preload commands")]
            [Switch]$Preload,

            [Parameter(HelpMessage="Reuse runspacePool")]
            [Switch]$reuseRunspacePool,

            [Parameter(Mandatory=$False, HelpMessage='ThrowOnRunspaceOpenError')]
            [Switch]$ThrowOnRunspaceOpenError
    )
    Begin{
        if (-not $PSBoundParameters.ContainsKey('ThrowOnRunspaceOpenError')) {
            $ThrowOnRunspaceOpenError = $False
        }
        #Check if should preload commands
        $commandInfo = Get-CommandInfo -ScriptBlock $ScriptBlock
        if($null -eq $commandInfo){
            foreach ($command in $ImportCommands){
                if($command -is [System.IO.FileInfo]){
                    . $command.FullName
                }
                elseif($command -is [System.String]){
                    . $command
                }
                else{
                    Write-Verbose ($script:messages.CommandNotRecognized)
                }
            }
        }
        if( -not $PSBoundParameters.ContainsKey('MaxQueue') ) {
            $MaxQueue = 3 * $MaxQueue
        }
        else {
            $MaxQueue = $MaxQueue
        }
        $Counter = 0
        $Jobs = @{}
        $Powershell = $null;
        [int]$script:jobsCollected = 0
        $Script:JobErrs = @()
        #Timer to keep track of time spent on each section
	    $Timer = [system.diagnostics.stopwatch]::StartNew()
        #SubTimer used to calculate time for batches
        $SubTimer = [system.diagnostics.stopwatch]::StartNew()
        $scriptBlockInfo = Get-ScriptBlockInfo -ScriptBlock $ScriptBlock
        if(-NOT $runspacepool){
            #Create a new runspacePool
            $localparams = @{
                ImportVariables = $ImportVariables;
                ImportModules = $ImportModules;
                ImportCommands = $ImportCommands;
                ImportCommandsAst = $ImportCommandAst;
                ApartmentState = $ApartmentState;
                Throttle = $Throttle;
                StartUpScripts = $StartUpScripts;
                ThrowOnRunspaceOpenError = $ThrowOnRunspaceOpenError;
            }
            #Get runspace pool
            $runspacepool = New-RunspacePool @localparams
            if($null -ne $runspacepool -and $runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                #Open runspace
                Write-Verbose ($script:messages.OpenRunspaceMessage)
                $runspacepool.Open()
            }
        }
        else{
            if($runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::BeforeOpen){
                #Open runspace
                Write-Verbose ($script:messages.OpenRunspaceMessage)
                $runspacepool.Open()
            }
        }
        if($null -ne $scriptBlockInfo -and $null -ne $scriptBlockInfo.dummyFunction -and $null -ne $scriptBlockInfo.dummyFunctionName){
            try{
                if(Get-Command -CommandType function | Where-Object{$_.name -eq $scriptBlockInfo.dummyFunctionName}){
                    #Remove duplicate dummy function
                    Remove-Item ("function:\{0}" -f $scriptBlockInfo.dummyFunctionName) -Confirm:$false
                }
                Write-Verbose ($script:messages.DummyFunctionMessage -f $scriptBlockInfo.dummyFunctionName)
                #Create new dummy function
                $param = @{
                    Path = ("function:\{0}" -f $scriptBlockInfo.dummyFunctionName);
                    Value = $scriptBlockInfo.dummyFunction.ToString();
                    ErrorAction = "Stop";
                    ErrorVariable = "MonkeyError";
                }
                New-Item @param | Out-Null
            }
            catch{
                Write-Error ($script:messages.UnableToCreateProxyCommand -f $_)
			    Break
            }
        }
    }
    Process{
        if($null -ne $scriptBlockInfo -and $null -ne $runspacepool -and $runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::Opened){
            $Powershell = New-PowerShellObject -Job $scriptBlockInfo
            if($null -ne $Powershell){
                $Counter++
                $newjob = @{
                    handle = $null
                    Thread = $Powershell
                    ScriptBlockInfo = $scriptBlockInfo
                    FunctionName = $scriptBlockInfo.commandName
                    MaxRunspaces = $runspacepool.GetMaxRunspaces()
                    startTime = Get-Date
                    Id = New-HumanGuid
                }
                #Add job
                [void]$Jobs.Add($Counter,$newjob)
            }
        }
        else{
            if($null -eq $scriptBlockInfo){
                Write-Error ($script:messages.ScriptBlockError)
                return
            }
            elseif($runspacepool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspaceState]::Opened){
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
            if($Jobs.Count -gt 0){
                $TotalJobs = $Jobs.Count
                for($NumJob = 1 ; $NumJob -le $TotalJobs ; $NumJob++){
                    $Job = $Jobs.Item($NumJob)
                    $Job.Thread.RunspacePool = $runspacepool
                    $Job.Handle = $Job.Thread.BeginInvoke()
                    #Check if maxQueue
                    if($NumJob -ge $MaxQueue){
                        $SubTimer.Stop()
                        Write-Verbose ($script:messages.TimeSpentInvokeBatchMessage -f ($NumJob / $BatchSize), $SubTimer.Elapsed.ToString())
			            $SubTimer.Reset();$SubTimer.Start()
                        $p = @{
                            Jobs = $Jobs;
                            BSize = $BatchSize;
                            Timeout = $Timeout;
                            Jobscollected = ([ref]$Script:jobsCollected);
                            JobsErrors = ([ref]$Script:JobErrs);
                        }
                        Get-JobStatus @p
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
                #All jobs are invoked at this time, just collect all of them using a bigger batchsize number
		        $NumJob = $NumJob - 1
		        Write-Verbose "Invoked all Jobs, Collecting the last jobs that are running"
                #Collect all jobs
                While ((@($Jobs.Values.Handle | Where-Object {$null -ne $_})).count -gt 0){
			        #We want to collect all the Jobs, so just double the BatchSize
			        $BatchSize = (@($Jobs.Values.GetEnumerator() | Where-Object {$null -ne $_.Handle})).count * 2
                    $p = @{
                        Jobs = $Jobs;
                        BSize = $BatchSize;
                        Timeout = $Timeout;
                        Jobscollected = ([ref]$Script:jobsCollected);
                        JobsErrors = ([ref]$Script:JobErrs);
                    }
                    Get-JobStatus @p
		        }
                If($Timer.Isrunning){
			        Write-Verbose $script:messages.StoppingTimerMessage
			        $Timer.Stop()
                    $Timer.Reset()
                }
            }
        }
        catch{
            Write-Error ("MonkeyJob Error: {0}" -f $_)
            Write-Verbose ("{0} at {1} with message {2}" -f $_.Exception, $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
            try{
                Write-Verbose ("Exception at {0}" -f $_.InvocationInfo.MyCommand.Name)
            }
            catch{
                Write-Verbose ("Exception at {0}" -f $_.InvocationInfo.MyCommand.CommandType)
            }
        }
        Finally{
            #Clean
            if($(@($Jobs.Values.GetEnumerator() | Where-Object {$null -ne $_.Handle} | Measure-Object )).count -gt 0){
			    Write-Verbose ($script:messages.TerminateJobMessage -f (@($Jobs.Values.GetEnumerator() | Where-Object{$null -ne $_.Handle} | Measure-Object ).count))
			    Foreach($Job in ($Jobs.Values.GetEnumerator() | Where-Object{$null -ne $_.Handle})){
				    $Job.Thread.stop()
				    $Job.Thread.Dispose()
				    $Job.Thread = $null
				    $Job.Handle = $null
			    }
		    }
            If($Timer.Isrunning){
			    Write-Verbose "Exiting script"
                Write-Verbose "Jobs Collected: $script:jobsCollected"
                Write-Verbose "Time took to Invoke and Complete the Jobs : $($Timer.Elapsed.ToString())"
			    $Timer.Stop()
            }
            if($null -ne $Powershell -and $Powershell -is [System.Management.Automation.PowerShell]){
			    $Powershell.dispose()
		    }
            if(!$reuseRunspacePool.IsPresent -and $null -ne $runspacepool -and $runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                Write-Verbose "Closing runspacePool"
                $runspacepool.Close()
                $runspacepool.Dispose()
            }
            if($null -ne (Get-Command -CommandType function | Where-Object{$_.name -eq $scriptBlockInfo.dummyFunctionName} -ErrorAction Ignore)){
                Write-Verbose ($script:messages.RemoveDummyFunctionMessage -f $scriptBlockInfo.dummyFunctionName)
                #Remove duplicate dummy function
                Remove-Item ("function:\{0}" -f $scriptBlockInfo.dummyFunctionName) -Confirm:$false
            }
            #add errors to var
            if($JobErrs -and $null -ne (Get-Variable -Name AllJobErrors -ErrorAction Ignore)){
                $script:AllJobErrors+=$Script:JobErrs
            }
            $Jobs.Clear()
		    $Jobs = $null
            #collect garbage
            #[gc]::Collect()
            [System.GC]::GetTotalMemory($true) | out-null
        }
    }
}
