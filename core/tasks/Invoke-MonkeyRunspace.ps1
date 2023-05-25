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
                $p = @{
			        Runspacepool = $runspacepool;
			        ReuseRunspacePool = $true;
                    MaxQueue = $MaxQueue;
			        Debug = $O365Object.VerboseOptions.Debug;
			        Verbose = $O365Object.VerboseOptions.Verbose;
			        BatchSleep = $O365Object.BatchSleep;
			        BatchSize = $O365Object.BatchSize;
                    InformationAction = $O365Object.InformationAction;
		        }
                $Id = ([System.Guid]::NewGuid()).ToString()
                $argument = @{pluginId = $Id}
                Invoke-MonkeyJob -Command $plugin.Name -Arguments $argument @p
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
    End{
        #Dispose runspacepool
        $runspacepool.Dispose()
        #collect garbage
        #[gc]::Collect()
        [System.GC]::GetTotalMemory($true) | out-null
    }
}
