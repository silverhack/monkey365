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

Function Invoke-MonkeyRunspace{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyRunspace
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(HelpMessage="Variables to import into runspace")]
        [Object]$ImportVariables,

        [Parameter(HelpMessage="modules to import into sessionState")]
        [Object]$ImportModules,

        [Parameter(HelpMessage="commands to import into sessionState")]
        [Object]$ImportCommands,

        [Parameter(HelpMessage="Plugins to execute")]
        [Object]$ImportPlugins,

        [Parameter(HelpMessage="Startup scripts (*ps1 files) to execute")]
        [System.Object[]]$StartUpScripts,

        [Parameter(HelpMessage="recursive search on import commands")]
        [Switch]$RecursiveCommandSearch,

        [Parameter(HelpMessage="Maximum number of concurrent threads")]
        [ValidateRange(1,65535)]
        [int32]$Throttle = 4,

        [Parameter(HelpMessage="Timeout before a thread stops trying to gather the information")]
        [ValidateRange(1,65535)]
        [int32]$Timeout = 30,

        [Parameter(HelpMessage="Increase Sleep Timer in seconds between child objects")]
        [ValidateRange(1,65535)]
        [int32]$SleepTimer = 5,

        [Parameter(HelpMessage="Pause between batchs in milliseconds")]
        [int32]$BatchSleep = 0,

        [Parameter(HelpMessage="BatchSize")]
        [int32]$BatchSize = 100,

        [Parameter(HelpMessage="Increase Sleep Timer in seconds between child objects")]
        [ValidateRange(1,65535)]
        [int32]$MaxQueue = 1,

        [Parameter(HelpMessage="ApartmentState of the thread")]
        [ValidateSet("STA","MTA")]
        [String]$ApartmentState = "STA",

        [Parameter(Mandatory=$False, HelpMessage='ThrowOnRunspaceOpenError')]
        [Switch]$ThrowOnRunspaceOpenError
    )
    Begin{
        if($null -eq $ImportPlugins){
            $msg = @{
                MessageData = ($message.UnableToCreateRunspacePool);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $script:InformationAction;
                Tags = @('RunspaceCreationError');
            }
            Write-Warning @msg
            return
        }
        $Jobs = @{}
        $Counter = 0;
        $PowerShell = $null;
        [int]$script:jobsCollected = 0
        Set-Variable MonkeyJobErrors -Value @() -Scope Script -Force
        #$Script:JobErrs = @()
        #Timer to keep track of time spent on each section
	    $Timer = [system.diagnostics.stopwatch]::StartNew()
        #SubTimer used to calculate time for batches
        $SubTimer = [system.diagnostics.stopwatch]::StartNew()
        if( -not $PSBoundParameters.ContainsKey('MaxQueue') ) {
            $script:MaxQueue = $Throttle * 3
        }
        else {
            $script:MaxQueue = $MaxQueue
        }
        $localparams = @{
            objects = $ImportPlugins;
            recursive = $RecursiveCommandSearch;
        }
        $all_plugins = Get-AstFunction @localparams
        if($null -ne $all_plugins){
            $localparams = @{
                ImportVariables = $ImportVariables;
                ImportModules = $ImportModules;
                ImportCommands = $ImportCommands;
                ImportCommandsAst = $all_plugins;
                ApartmentState = $ApartmentState;
                Throttle = $Throttle;
                StartUpScripts = $StartUpScripts;
                ThrowOnRunspaceOpenError = $true;
            }
            #Get runspace pool
            $runspacepool = New-RunspacePool @localparams
        }
        else{
            $msg = @{
                MessageData = ($message.UnableToCreateRunspacePool);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $script:InformationAction;
                Tags = @('RunspaceCreationError');
            }
            Write-Warning @msg
            $runspacepool = $null
        }
        if($null -ne $runspacepool -and $runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
            $runspacepool.Open()
        }
    }
    Process{
        if($null -ne $runspacepool -and $null -ne $all_plugins -and $runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::Opened){
            foreach($plugin in $all_plugins){
                if($null -ne $plugin -and $plugin -is [System.Management.Automation.Language.FunctionDefinitionAst]){
                    $Counter++
                    $JobId = New-HumanGuid
                    $PowerShell = [System.Management.Automation.PowerShell]::Create()
                    [void]$PowerShell.AddCommand($plugin.Name)
                    [void]$PowerShell.AddParameter('pluginId',$JobId)
                    $newjob = @{
                        handle = $null
                        Thread = $Powershell
                        ScriptBlockInfo = $null
                        FunctionName = $plugin.Name
                        MaxRunspaces = $runspacepool.GetMaxRunspaces()
                        startTime = Get-Date
                        Id = $JobId
                    }
                    #Add job
                    [void]$Jobs.Add($Counter,$newjob)
                }
            }
        }
        else{
            if($runspacepool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspaceState]::Opened){
                Write-Error ($message.RunspaceError)
                return
            }
            else{
                Write-Error ($message.UnknownError)
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
                        $SubTimer.Stop();
                        $msg = @{
                            MessageData = ($message.TimeSpentInvokeBatchMessage -f ($NumJob / $BatchSize), $SubTimer.Elapsed.ToString());
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            Tags = @('MonkeyRunspaceTimeSpentInvokeBachJobs');
                        }
                        Write-Verbose @msg
			            $SubTimer.Reset();
                        $SubTimer.Start();
                        $p = @{
                            Jobs = $Jobs;
                            BSize = $BatchSize;
                            Timeout = $Timeout;
                            Jobscollected = ([ref]$Script:jobsCollected);
                            JobsErrors = ([ref]$Script:MonkeyJobErrors);
                        }
                        Get-JobStatus @p
                        $SubTimer.Stop()
                        $msg = @{
                            MessageData = ($message.TimeSpentCollectBatchMessage -f ($NumJob / $BatchSize), $SubTimer.Elapsed.ToString());
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            Tags = @('MonkeyRunspaceTimeSpentCollectBachJobs');
                        }
			            Write-Verbose @msg
			            $SubTimer.Reset()
                        if($BatchSleep){
                            Write-Verbose ($message.SleepMessage -f $BatchSleep)
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
                        JobsErrors = ([ref]$Script:MonkeyJobErrors);
                    }
                    Get-JobStatus @p
		        }
                If($Timer.Isrunning){
			        #Write-Verbose $script:messages.StoppingTimerMessage
			        $Timer.Stop()
                    $Timer.Reset()
                }
            }
        }
        catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                Tags = @('MonkeyRunspaceError');
            }
            Write-Verbose @msg
        }
        Finally{
            #Clean
            if($(@($Jobs.Values.GetEnumerator() | Where-Object {$null -ne $_.Handle} | Measure-Object )).count -gt 0){
			    $msg = @{
                    MessageData = ($message.TerminateJobMessage -f (@($Jobs.Values.GetEnumerator() | Where-Object{$null -ne $_.Handle} | Measure-Object ).count));
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Tags = @('MonkeyTerminatingJobs');
                }
                Write-Verbose @msg
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
            if($null -ne $PowerShell -and $PowerShell -is [System.Management.Automation.PowerShell]){
			    $Powershell.dispose()
		    }
            if($null -ne $runspacepool -and $runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                $runspacepool.Close()
                $runspacepool.Dispose()
            }
            #collect garbage
            #[gc]::Collect()
            [System.GC]::GetTotalMemory($true) | out-null
        }
    }
}
