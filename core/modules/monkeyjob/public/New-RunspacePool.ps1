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

Function New-RunspacePool{
    <#
        .SYNOPSIS
            Create a new runspace pool
        .DESCRIPTION
            Set a pool of runspaces that specifies the minimum and maximum number of opened runspaces.
        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-RunspacePool
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
        .PARAMETER Throttle
            Defines the maximum number of pipelines that can be concurrently executed on the pool.
            The number of available pools determined the maximum number of processes that can be running concurrently.
        .PARAMETER ImportVariables
            An Object which will be make available to entire runspace pool
        .PARAMETER ImportModules
            An Object with PowerShell modules that will be make available to entire runspace pool
        .PARAMETER ImportCommands
            An Object with PowerShell commands that will be make available to entire runspace pool
        .PARAMETER ImportCommandsAst
            An Object with PowerShell AST commands that will be make available to entire runspace pool
        .PARAMETER ApartmentState
            Create runspaces in a multi-threaded apartment. It is not recommended to use this option unless absolutely necessary.
        .PARAMETER CleanUp
            Set how often unused runspaces are disposed.
        .EXAMPLE
            Creates a pool of 4 runspaces.
            $RunSpacePool = New-RunSpacePool -Throttle 4
        .EXAMPLE
            Creates a pool of 4 runspaces with synchronized object (HashTable)
            $SyncHashTable = [HashTable]::Synchronized(@{})
            $RunSpacePool = New-RunSpacePool -Throttle 4 -ImportVariables @($SyncHashTable)
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.RunspacePool])]
    Param
    (
        [Parameter(HelpMessage="Variables to import into runspace")]
        [Object]$ImportVariables,

        [Parameter(HelpMessage="modules to import into sessionState")]
        [Object]$ImportModules,

        [Parameter(HelpMessage="commands to import into sessionState")]
        [Object]$ImportCommands,

        [Parameter(HelpMessage="commands as StatementAst to import into sessionState")]
        [Object]$ImportCommandsAst,

        [Parameter(HelpMessage="Startup scripts (*ps1 files) to execute")]
        [System.Object[]]$StartUpScripts,

        [Parameter(HelpMessage="Minimum number of runspaces")]
        [ValidateRange(1,65535)]
        [int32]$MinThrottle = 1,

        [Parameter(HelpMessage="Maximum number of runspaces")]
        [ValidateRange(1,65535)]
        [int32]$Throttle = 10,

        [Parameter(HelpMessage="ApartmentState of the thread")]
        [ValidateSet("STA","MTA")]
        [String]$ApartmentState = "STA",

        [Parameter(HelpMessage="Thread Option")]
        [ValidateSet("Default","UseNewThread","ReuseThread","UseCurrentThread")]
        [String]$ThreadOption = "Default",

        [Parameter(Mandatory=$False, HelpMessage='Cleanup interval')]
        [int]$Cleanup = 2,

        [Parameter(Mandatory=$False, HelpMessage='ThrowOnRunspaceOpenError')]
        [Switch]$ThrowOnRunspaceOpenError
    )
    Begin{
        $Verbose = $False;
        $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $DebugPreference = 'Continue'
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        if (-not $PSBoundParameters.ContainsKey('ThrowOnRunspaceOpenError')) {
            $ThrowOnRunspaceOpenError = $False
        }
        $runspacepool = $null;
        #Create initial session state
        $localparams = @{
            ImportVariables = $ImportVariables;
            ImportModules = $ImportModules;
            ImportCommands = $ImportCommands;
            ImportCommandsAst = $ImportCommandsAst;
            ApartmentState = $ApartmentState;
            StartUpScripts = $StartUpScripts;
            ThrowOnRunspaceOpenError = $ThrowOnRunspaceOpenError;
            Verbose = $Verbose;
            Debug = $Debug;
            InformationAction = $InformationAction;
        }
        #Get Initial Session State
        $sessionstate = New-InitialSessionState @localparams
    }
    Process{
        #Create runspacePool
        if($null -ne $sessionstate -and $sessionstate -is [System.Management.Automation.Runspaces.InitialSessionState]){
            try{
                $runspacepool = [runspacefactory]::CreateRunspacePool($MinThrottle, $Throttle, $sessionstate, $Host)
                #Set state (STA/MTA)
                $runspacepool.ApartmentState = [System.Threading.ApartmentState]::$ApartmentState
                #Set options
                $runspacepool.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::$ThreadOption
                #Set cleanup interval
                $runspacepool.CleanupInterval = $Cleanup * [timespan]::TicksPerMinute
                #Set min runspaces
                [void]$runspacepool.SetMinRunspaces($MinThrottle)
                #Set max runspaces
                [void]$runspacepool.SetMaxRunspaces($Throttle)
            }
            catch{
                Write-Warning $script:messages.RunspaceCreationError
                Write-Verbose $_
                $runspacepool = $null
            }
        }
        else{
            Write-Warning $script:messages.ISSCreationError
            $runspacepool = $null
        }
    }
    End{
        #return runspace
        return $runspacepool
    }
}
