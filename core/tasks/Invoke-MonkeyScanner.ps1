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

Function Invoke-MonkeyScanner{
    <#
        .SYNOPSIS
        Sets up a new scan with a custom configuration, variables and a Runspace

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyScanner
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("InjectionRisk.Create", "", Scope="Function")]
	Param (
        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraID","Microsoft365")]
        [String]$Provider = "Azure",

        [Parameter(Mandatory=$false, HelpMessage="Out data")]
        [Object]$ReturnData,

        [Parameter(Mandatory=$false, HelpMessage="Change the threads settings. Default is 2")]
        [int32]$Throttle = 2,

        [Parameter(Mandatory=$false, HelpMessage="ApartmentState of the thread")]
        [ValidateSet("STA","MTA")]
        [String]$ApartmentState = "STA",

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
        [int32]$MaxQueue = 1
    )
    Begin{
        $rdata = $null
        #set MaxQueue
        if( -not $PSBoundParameters.ContainsKey('MaxQueue') ) {
            $MaxQueue = $Throttle * 3
        }
        else {
            $MaxQueue = $MaxQueue
        }
        #Set runspaces array
        $all_scans = [System.Collections.Generic.List[System.Collections.Hashtable]]::new();
    }
    Process{
        #Get Initialize-MonkeyRuleset params
        $newPsboundParams = [ordered]@{}
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Initialize-MonkeyScan")
        if($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters.Item($p))
                }
            }
        }
        $all_scans = Initialize-MonkeyScan @newPsboundParams
        #Get ReturnData object
        if($PSBoundParameters.ContainsKey('ReturnData') -and $PSBoundParameters['ReturnData']){
            $rdata = $PSBoundParameters['ReturnData'];
        }
        elseif($null -ne (Get-Variable -Name returnData -ErrorAction Ignore)){
            $rdata = (Get-Variable -Name returnData -ErrorAction Ignore).Value;
        }
        else{
            Set-Variable returnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
            $rdata = (Get-Variable -Name returnData -ErrorAction Ignore).Value;
        }
        #Populate vars
        foreach($scan in $all_scans){
            #Set synchronized hashtable
            $scan.vars.returnData = $rdata;
        }
        #Populate runspace vars
        $rndScan = $all_scans.Where({$null -ne $_.vars}) | Select-Object -First 1
        if($null -ne $rndScan){
            $O365Object.runspace_vars = $rndScan.vars;
        }
    }
    End{
        If($null -ne $all_scans -and @($all_scans).Count -gt 0){
            #Set runspaces array
            $all_runspaces = [System.Collections.Generic.List[System.Management.Automation.Runspaces.RunspacePool]]::new();
            #Launch scans
            try{
                #Set nested runspace
                $myscan = $all_scans | Select-Object -First 1
                #Get all libs
                $libs = $all_scans.libCommands | Select-Object -Unique
                if($null -ne $myscan){
                    $nestedParam = @{
                        ImportVariables = $myscan.vars;
                        ImportModules = $myscan.modules;
                        ImportCommands = $libs;
                        ApartmentState = $myscan.apartmentState;
                        Throttle = $myscan.threads;
                        StartUpScripts = $myscan.startUpScripts;
                        ThrowOnRunspaceOpenError = $true;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    #Set a second runspace for nested executions
                    $nestedRunspace = New-RunspacePool @nestedParam
                    if($null -ne $nestedRunspace -and $nestedRunspace -is [System.Management.Automation.Runspaces.RunspacePool]){
                        #Add to array
                        [void]$all_runspaces.Add($nestedRunspace)
                        #Add to object
                        $O365Object.monkey_runspacePool = $nestedRunspace;
                    }
                }
                foreach($scan in $all_scans.GetEnumerator()){
                    $msg = @{
                        MessageData = ("Starting new scan for {0}" -f $scan.scanName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365Scanner');
                    }
                    Write-Information @msg
                    #Set Generic list
                    $commands = [System.Collections.Generic.List[System.Object]]::new();
                    #Add collectors to libcommands
                    foreach($collector in @($scan.collectors)){
                        [void]$commands.Add($collector.File);
                    }
                    #Add commands
                    foreach($command in @($scan.libCommands)){
                        [void]$commands.Add($command);
                    }
                    $rsParam = @{
                        ImportVariables = $scan.vars;
                        ImportModules = $scan.modules;
                        ImportCommands = $commands;
                        ApartmentState = $scan.apartmentState;
                        Throttle = $scan.threads;
                        StartUpScripts = $scan.startUpScripts;
                        ThrowOnRunspaceOpenError = $true;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    #Get runspace pool
                    $runspacepool = New-RunspacePool @rsParam
                    if($null -ne $runspacepool -and $runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                        $runspacepool.Open()
                        #Add to array
                        [void]$all_runspaces.Add($runspacepool)
                    }
                    if($null -ne $runspacepool -and $runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::Opened){
                        foreach($collector in $scan.collectors){
                            $p = @{
			                    Runspacepool = $runspacepool;
			                    ReuseRunspacePool = $true;
                                MaxQueue = $MaxQueue;
			                    Debug = $O365Object.Debug;
			                    Verbose = $O365Object.Verbose;
			                    BatchSleep = $O365Object.BatchSleep;
			                    BatchSize = $O365Object.BatchSize;
                                InformationAction = $O365Object.InformationAction;
		                    }
                            $Id = ([System.Guid]::NewGuid()).ToString()
                            $argument = @{CollectorId = $Id}
                            #$sb = [ScriptBlock]::Create('{0}' -f $collector.File.FullName)
                            Invoke-MonkeyJob -Command $collector.collectorName -Arguments $argument @p
                        }
                    }
                    else{
                        if($null -ne $runspacepool -and $runspacepool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspaceState]::Opened){
                            Write-Error ($message.RunspaceError)
                            return
                        }
                        else{
                            Write-Error ($message.UnknownError)
                            return
                        }
                    }
                }
            }
            Catch{
                Write-Error $_
            }
            Finally{
                #Dispose all runspacepool
                foreach($rs in $all_runspaces){
                    $rs.Dispose()
                }
                #collect garbage
                #[gc]::Collect()
                [System.GC]::GetTotalMemory($true) | out-null
            }
        }
        Else{
            $msg = @{
                MessageData = ("Unable to initialize the Monkey365 scan for {0}. Collectors for {1} are empty" -f $Provider, $Provider);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365Scanner');
            }
            Write-Warning @msg
        }
    }
}
