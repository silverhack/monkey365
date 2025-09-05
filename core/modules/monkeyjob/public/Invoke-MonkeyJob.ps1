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
        $Verbose = $False;
        $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        If($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        If($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $DebugPreference = 'Continue'
            $Debug = $True
        }
        If($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        If($PSBoundParameters.ContainsKey('ReuseRunspacePool') -and $PSBoundParameters['ReuseRunspacePool'].IsPresent){
            $reuseRSP = $True
        }
        Else{
            $reuseRSP = $false
        }
        If (-not $PSBoundParameters.ContainsKey('ThrowOnRunspaceOpenError')) {
            $ThrowOnRunspaceOpenError = $False
        }
        IF( -not $PSBoundParameters.ContainsKey('MaxQueue') ) {
            $MaxQueue = 3 * $MaxQueue
        }
        Else {
            $MaxQueue = $MaxQueue
        }
        if($PSBoundParameters.ContainsKey('Runspacepool') -and $PSBoundParameters['Runspacepool']){
            if($Runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::BeforeOpen){
                #Open runspace
                Write-Verbose $script:messages.OpenRunspaceMessage
                $Runspacepool.Open()
            }
        }
        Else{
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
                Verbose = $Verbose;
                Debug = $Debug;
                InformationAction = $InformationAction;
            }
            #Get runspace pool
            $Runspacepool = New-RunspacePool @localparams
            If($null -ne $Runspacepool -and $Runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                #Open runspace
                Write-Verbose $script:messages.OpenRunspaceMessage
                $Runspacepool.Open()
                #Add RunspacePool to array
                If($null -ne (Get-Variable -Name MonkeyRSP -ErrorAction Ignore)){
                    [void]$MonkeyRSP.Add($Runspacepool);
                }
            }
        }
        #Set Monkeyjobs variable
        $MyMonkeyJobs = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        #Set timers, vars
        $Timer = [system.diagnostics.stopwatch]::StartNew()
        $SubTimer = [system.diagnostics.stopwatch]::StartNew()
        [int]$script:jobsCollected = 0
        If($PSBoundParameters.ContainsKey('Timeout') -and $PSBoundParameters['TimeOut']){
            #TimeOut is in Milliseconds
            [int]$Timeout = $PSBoundParameters['TimeOut'] * 1000
        }
        Else{
            #TimeOut is in Milliseconds
            [int]$Timeout = 10 * 1000
        }
    }
    Process{
        If($null -ne $Runspacepool -and $Runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::Opened){
            #Check If MaxQueue
            If($MyMonkeyJobs.Count -ge $MaxQueue){
                Write-Verbose ($script:messages.TimeSpentInvokeBatchMessage -f ($MyMonkeyJobs.Count / $BatchSize), $SubTimer.Elapsed.ToString())
                $SubTimer.Reset();$SubTimer.Start()
                $p = @{
                    Jobs = $MyMonkeyJobs;
                    BatchSize = $BatchSize;
                    Timeout = $Timeout;
                    Jobscollected = ([ref]$Script:jobsCollected);
                }
                Watch-MonkeyJob @p
                $SubTimer.Stop()
                Write-Verbose ($script:messages.TimeSpentCollectBatchMessage -f ($MyMonkeyJobs.Count / $BatchSize), $SubTimer.Elapsed.ToString())
                $SubTimer.Reset()
                If($BatchSleep){
                    Write-Verbose ($script:messages.SleepMessage -f $BatchSleep)
                    Start-Sleep -Milliseconds $BatchSleep
                }
                $SubTimer.Start()
                $MaxQueue += $BatchSize
            }
            #Get Start-MonkeyJob Param
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Start-MonkeyJob")
            $newPsboundParams = @{}
            If($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                ForEach($p in $param.GetEnumerator()){
                    If($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
            }
            #Check if RunspacePool
            If(-NOT $newPsboundParams.ContainsKey('RunspacePool')){
                [void]$newPsboundParams.Add('RunspacePool',$Runspacepool);
            }
            $newJob = Start-MonkeyJob @newPsboundParams
            IF($newJob){
                #Add to list
                [void]$MyMonkeyJobs.Add($newJob);
            }
        }
        Else{
            If($Runspacepool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspaceState]::Opened){
                Write-Error ($script:messages.RunspaceError)
                return
            }
            Else{
                Write-Error ($script:messages.UnknownError)
                return
            }
        }
    }
    End{
        Try{
            #All jobs are invoked at this time, just collect all of them
            Write-Verbose "Invoked all Jobs, Collecting the last jobs that are running"
            #Collect all jobs
            While ((@($MyMonkeyJobs | Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Running})).count -gt 0){
                #We want to collect all the Jobs, so just double the BatchSize
			    $BS = (@($MyMonkeyJobs | Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Running})).count * 2
                $p = @{
                    Jobs = $MyMonkeyJobs;
                    BatchSize = $BS;
                    Timeout = $Timeout;
                    Jobscollected = ([ref]$Script:jobsCollected);
                }
                Watch-MonkeyJob @p
            }
        }
        Catch{
            Write-Error ("MonkeyJob Error: {0}" -f $_)
        }
        Finally{
            #Get Data
            $completedJobs = $MyMonkeyJobs | Where-Object {$_.Job.State -eq [System.Management.Automation.JobState]::Completed}
            #Receive jobs
            $completedJobs | Receive-MonkeyJob
            #Clean objects
            if($MyMonkeyJobs.Count -gt 0){
                Write-Verbose ($script:messages.TerminateJobMessage -f $MyMonkeyJobs.Count)
                If($reuseRSP){
                    #$MyMonkeyJobs | Remove-MonkeyJob -KeepRunspacePool
                }
                Else{
                    #$MyMonkeyJobs | Remove-MonkeyJob
                }
            }
            #Stop timer
            If($Timer.Isrunning){
			    Write-Verbose "Exiting script"
                Write-Verbose ("Jobs Collected: {0}" -f $script:jobsCollected)
                Write-Verbose ("Time took to Invoke and Complete the Jobs : {0}" -f $Timer.Elapsed.ToString())
			    $Timer.Stop()
            }
        }
    }
}
