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
# See the License for the specIfic language governing permissions and
# limitations under the License.

Function New-Logger{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-Logger
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "Loggers")]
        [Array]$Loggers=@(),

        [parameter(Mandatory= $false, HelpMessage= "Initial path")]
        [String]$InitialPath,

        [parameter(Mandatory= $false, HelpMessage= "Queue logger")]
        [System.Collections.Concurrent.BlockingCollection`1[System.Management.Automation.InformationRecord]]$LogQueue,

        [parameter(Mandatory= $false, HelpMessage= "Force creation")]
        [Switch]$Force
    )
    Try{
        $alreadyInUse = $false;
        If($null -ne (Get-Variable -Name monkeyLogger -ErrorAction Ignore)){
            If($monkeyLogger.isEnabled -eq $false){
                $alreadyInUse = $false
            }
            Else{
                $alreadyInUse = $true
            }
        }
        If($Force.IsPresent -or $alreadyInUse -eq $false){
            #Check informationAction
            If(-NOT $PSBoundParameters.ContainsKey('InformationAction')){
                $PSBoundParameters.Add('InformationAction',$InformationPreference);
            }
            #Check Debug
            If($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
                $verbosity=@{Debug=$true}
                $DebugPreference = 'Continue'
            }
            Else{
                $verbosity=@{Debug=$false}
            }
            If($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
                $verbosity.Add("Verbose",$true)
                $VerbosePreference = 'Continue'
            }
            Else{
                $verbosity.Add("Verbose",$false)
            }
            #Check Log Queue
            If(-NOT $PSBoundParameters.ContainsKey('LogQueue')){
                New-Variable -Name MonkeyLogQueue -Scope Script `
                                    -Value ([System.Collections.Concurrent.BlockingCollection[System.Management.Automation.InformationRecord]]::new()) -Force
            }
            Else{
                New-Variable -Name MonkeyLogQueue -Scope Script -Value $PSBoundParameters['LogQueue'] -Force
            }
            #Create object
            $logger = [PsCustomObject]@{
                path = $Script:modulePath
                callStack = (Get-PSCallStack | Select-Object -First 1);
                callers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
                isEnabled = $false;
                funcDefinitions = [System.Collections.Generic.List[System.Management.Automation.Language.FunctionDefinitionAst]]::new();
                validationFunctions = [System.Collections.Generic.List[System.Management.Automation.Language.FunctionDefinitionAst]]::new();
                helperFunctions = [System.Collections.Generic.List[System.Management.Automation.Language.FunctionDefinitionAst]]::new();
                informationAction = $PSBoundParameters['InformationAction'];
                verbosity= $verbosity;
                verbose = $verbosity.Verbose;
                debug = $verbosity.Debug;
                debugPreference = $DebugPreference;
                verbosePreference = $VerbosePreference;
                loggers = $Loggers;
                enabledLoggers = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
                rootPath = $null;
                initialPath = $InitialPath;
                logQueue = $Script:MonkeyLogQueue;
            }
            #Set informationAction, debug and verbose variables
            New-Variable -Name monkeyloggerinfoAction -Scope Script -Value $PSBoundParameters.informationAction -Force
            #New-Variable -Name informationAction -Scope Script -Value $informationAction -Force
            New-Variable -Name Debug -Scope Script -Value $verbosity.Debug -Force
            New-Variable -Name Verbose -Scope Script -Value $verbosity.Verbose -Force
            #Load configuration
            $logger | Add-Member -Type ScriptMethod -Name loadConfig -Value {
                #Check if already loaded
                If($this.callers.Count -eq 0 -and $this.funcDefinitions.Count -eq 0 -and $this.validationFunctions.Count -eq 0){
                    #Load configuration files
                    $conf_path = ("{0}{1}clients{2}definitions" -f $this.path,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
                    $conf_files = [System.IO.Directory]::EnumerateFiles($conf_path,"*.json",[System.IO.SearchOption]::TopDirectoryOnly).Where({$_.EndsWith('.json')})
                    ForEach($conf_file in $conf_files){
                        $_caller = Get-Content $conf_file -Raw | ConvertFrom-Json -ErrorAction Ignore
                        If($null -ne $_caller){
                            [void]$this.callers.Add($_caller)
                        }
                    }
                    #Load output scripts
                    $conf_path = ("{0}{1}clients" -f $this.path,[System.IO.Path]::DirectorySeparatorChar)
                    $output_callers = [System.IO.Directory]::EnumerateFiles($conf_path,"*.ps1",[System.IO.SearchOption]::TopDirectoryOnly).Where({$_.EndsWith('.ps1')})
                    #Set null
                    $tokens = $errors = $null
                    ForEach ($caller in $output_callers){
                        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                            $caller,
                            [ref]$tokens,
                            [ref]$errors
                        )
                        $fnc = $ast.Find({
                                    Param([System.Management.Automation.Language.Ast] $Ast)

                                    $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                    # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                                    ($PSVersionTable.PSVersion.Major -lt 5 -or
                                    $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

                                }, $true)
                        If($null -ne $fnc){
                            [void]$this.funcDefinitions.Add($fnc)
                        }
                    }
                    #Add validation functions
                    $validators_path = ("{0}{1}clients{2}validators" -f $this.path,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
                    $validator_functions = [System.IO.Directory]::EnumerateFiles($validators_path,"*.ps1",[System.IO.SearchOption]::TopDirectoryOnly).Where({$_.EndsWith('.ps1')})
                    #Set null
                    $tokens = $errors = $null
                    ForEach ($validator in $validator_functions){
                        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                            $validator,
                            [ref]$tokens,
                            [ref]$errors
                        )
                        $fnc = $ast.Find({
                                    Param([System.Management.Automation.Language.Ast] $Ast)

                                    $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                    # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                                    ($PSVersionTable.PSVersion.Major -lt 5 -or
                                    $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

                                }, $true)
                        If($null -ne $fnc){
                            [void]$this.validationFunctions.Add($fnc)
                        }
                    }
                    #Add helpers functions
                    $helpers_path = ("{0}{1}private{2}helpers" -f $this.path,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
                    $helpers_functions = [System.IO.Directory]::EnumerateFiles($helpers_path,"*.ps1",[System.IO.SearchOption]::TopDirectoryOnly).Where({$_.EndsWith('.ps1')})
                    #Set null
                    $tokens = $errors = $null
                    ForEach ($helper in $helpers_functions){
                        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                            $helper,
                            [ref]$tokens,
                            [ref]$errors
                        )
                        $fnc = $ast.Find({
                                    Param([System.Management.Automation.Language.Ast] $Ast)

                                    $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                    # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                                    ($PSVersionTable.PSVersion.Major -lt 5 -or
                                    $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

                                }, $true)
                        If($null -ne $fnc){
                            [void]$this.helperFunctions.Add($fnc)
                        }
                    }
                }
                Else{
                    $msg = [hashtable] @{
                        MessageData = $Script:messages.ConfigurationAlreadyLoaded
                        InformationAction = $this.informationAction
                        CallStack = $this.callStack
                        ForeGroundColor = "Yellow"
                        tags = @('MonkeyLog')
                    }
                    Write-Warning @msg
                    return
                }
            }
            #Add init loggers method
            $logger | Add-Member -Type ScriptMethod -Name initLoggers -Value {
                Try{
                    If($this.callers.Count -eq 0 -or $this.funcDefinitions.Count -eq 0){
                        $msg = [hashtable] @{
                            MessageData = $Script:messages.ConfigurationNotLoaded
                            InformationAction = $this.informationAction
                            CallStack = $this.callStack
                            ForeGroundColor = "Yellow"
                            tags = @('MonkeyLog')
                        }
                        Write-Warning @msg
                        return
                    }
                    $msg = [hashtable] @{
                        MessageData = $Script:messages.InitializingLoggers
                        InformationAction = $this.informationAction
                        CallStack = $this.callStack
                        ForeGroundColor = "Green"
                        tags = @('MonkeyLog')
                    }
                    Write-Information @msg
                    ForEach($new_logger in $this.loggers.GetEnumerator()){
                        #Check If should validate conf
                        Try{
                            #Set null
                            $validate_function = $null;
                            #Check if an initial validation is needed
                            $should_validate = @($this.callers).Where({$null -ne $_ -and $_.name -eq $new_logger.type}) | Select-Object -ExpandProperty validate -ErrorAction Ignore
                            If($null -ne $should_validate){
                                $_function = @($this.validationFunctions).Where({$null -ne $_ -and $_.Name -eq $should_validate})
                                If($_function.Count -gt 0){
                                    $validate_function = $_function.Body.GetScriptBlock()
                                }
                            }
                            If($new_logger.configuration -and $null -ne $validate_function){
                                $config = Initialize-Configuration -Configuration $new_logger.configuration
                                If($null -ne $config){
                                    $status = Invoke-Command -ScriptBlock $validate_function -ArgumentList $config
                                    If($status -eq $false){
                                        continue;
                                    }
                                }
                            }
                            $internal_func = @($this.callers).Where({$_.name -eq $new_logger.type}) | Select-Object -ExpandProperty function -ErrorAction Ignore
                            #check If internal function exists
                            If($null -ne $internal_func){
                                $exists = @($this.funcDefinitions).Where({$_.name -eq $internal_func})
                                If($internal_func -and $exists.Count -gt 0){
                                    $new_logger | Add-Member -Type NoteProperty -name function -value $internal_func -Force
                                    #Add enabled logger
                                    [void]$this.enabledLoggers.Add($new_logger);
                                }
                            }
                        }
                        Catch{
                            $msg = [hashtable] @{
                                MessageData = $_.Exception.Message
                                CallStack = $this.CallStack
                                ForeGroundColor = "Red"
                                tags = @('MonkeyLog')
                            }
                            Write-Error @msg
                        }
                    }
                }
                Catch{
                    $msg = [hashtable] @{
                        Message = $_
                        InformationAction = $this.informationAction
                        CallStack = $this.CallStack
                        tags = @('MonkeyLog')
                    }
                    Write-Error @msg
                }
            }
            #Add start method
            $logger | Add-Member -Type ScriptMethod -Name start -Value {
                If($null -ne (Get-Variable -Name MonkeyLogQueue -ErrorAction Ignore) -and $MonkeyLogQueue.IsAddingCompleted -eq $false){
                    #Check If log is enabled
                    If($this.isEnabled){
                        $msg = [hashtable] @{
                            MessageData = $Script:messages.LogAlreadyActive
                            InformationAction = $this.informationAction
                            CallStack = $this.CallStack
                            ForeGroundColor = "Green"
                            tags = @('MonkeyLog')
                        }
                        Write-Information @msg
                        return
                    }
                    #Load config
                    $this.loadConfig()
                    #Load loggers
                    If($this.callers.Count -gt 0 -or $this.funcDefinitions.Count -gt 0 -or $this.validationFunctions.Count -gt 0){
                        $this.initLoggers()
                    }
                    #Set variables
                    New-Variable -Name MonkeyLogRunspace -Scope Script -Option ReadOnly `
                                 -Value ([hashtable]::Synchronized(@{ })) -Force
                    New-Variable -Name _handle -Scope Script -Option ReadOnly `
                                 -Value ([System.Threading.ManualResetEventSlim]::new($false)) -Force
                    New-Variable -Name enabledLoggers -Scope Script -Value $this.enabledLoggers -Force

                    $session_vars = @{
                        "MonkeyLogQueue"=$Script:MonkeyLogQueue;
                        "_handle"=$_handle;
                        "logger" = $this;
                    }
                    #Add DebugPreference and VerbosePreference to session state
                    If($this.Debug){
                        [void]$session_vars.Add('DebugPreference','Continue')
                    }
                    If($this.Verbose){
                        [void]$session_vars.Add('VerbosePreference','Continue')
                    }
                    #
                    $Script:InitialSessionState = New-LoggerSessionState -ImportVariables $session_vars -ApartmentState MTA
                    #Setup runspace
                    $Script:MonkeyLogRunspace.Runspace = [runspacefactory]::CreateRunspace($Host,$Script:InitialSessionState)
                    $Script:MonkeyLogRunspace.Runspace.Name = 'Monkey365LogRunspace'
                    $Script:MonkeyLogRunspace.Runspace.Open();
                    $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('parentHost', $Host);
                    $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('VerbosePreference', $VerbosePreference);
                    $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('DebugPreference', $DebugPreference);
                    $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('verbosity', $this.verbosity)
                    $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('Debug', $this.debug)
                    $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('Verbose', $this.verbose)
                    $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('InformationAction', $this.informationAction)
                    #Set location
                    If($PSBoundParameters.ContainsKey('InitialPath') -and $PSBoundParameters['InitialPath']){
                        $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.Path.SetLocation($InitialPath);
                    }
                    Try{
                        # Add the functions into the runspace
                        @($this.funcDefinitions).Where({$null -ne $_}).Foreach(
                            {
                                [void]$Script:MonkeyLogRunspace.Runspace.SessionStateProxy.InvokeProvider.Item.Set(
                                'function:\{0}' -f $_.Name,
                                $_.Body.GetScriptBlock())
                            }
                        )
                        #Add the Write-Information/Debug/Warning/Verbose functions to sessionStateProxy
                        $proxy_fncs = @('Write-Information','Write-Warning','Write-Debug','Write-Verbose','Write-Error')
                        foreach($p_fnc in $proxy_fncs){
                            $_fnc = Get-Content ("function:\{0}" -f $p_fnc)
                            If($null -ne $_fnc){
                                [void]$Script:MonkeyLogRunspace.Runspace.SessionStateProxy.InvokeProvider.Item.Set(
                                    'function:\{0}' -f $_fnc.Ast.Name,
                                    $_fnc.Ast.Body.GetScriptBlock())
                            }
                        }
                        # Add helper functions into the runspace
                        @($this.helperFunctions).Where({$null -ne $_}).Foreach(
                            {
                                [void]$Script:MonkeyLogRunspace.Runspace.SessionStateProxy.InvokeProvider.Item.Set(
                                'function:\{0}' -f $_.Name,
                                $_.Body.GetScriptBlock())
                            }
                        )
                    }
                    Catch{
                        $msg = [hashtable] @{
                            MessageData = $_.Exception.Message
                            InformationAction = $this.informationAction
                            CallStack = $this.CallStack
                            ForeGroundColor = "Red"
                            tags = @('MonkeyLog')
                        }
                        Write-Error @msg
                    }
                    $_handle.Set(); #
                    # Spawn Logging Consumer
                    $Consumer = {
                        Try{
                            # Lock LogQueue
                            [System.Threading.Monitor]::Enter($MonkeyLogQueue)
                            $lock = $true
                            foreach ($Log in $MonkeyLogQueue.GetConsumingEnumerable()) {
                                ForEach($channel in $logger.enabledLoggers){
                                    Try{
                                        $function = Get-Content ("function:\{0}" -f $channel.function)
                                        If($null -ne $function){
                                            $ArgumentList = @{Log=$Log;Configuration=$channel.configuration}
                                            $publish = Confirm-Publication @ArgumentList
                                            If($publish){
                                                $p = @{
                                                    ScriptBlock = {.$function @ArgumentList}
                                                }
                                                Invoke-Command @p
                                            }
                                        }
                                    }
                                    Catch{
                                        $msg = [hashtable] @{
                                            MessageData = $_.Exception.Message
                                            InformationAction = $this.informationAction
                                            CallStack = $this.CallStack
                                            tags = @('MonkeyLog')
                                        }
                                        Write-Error @msg
                                    }
                                }
                            }
                        }
                        Catch{
                            $msg = [hashtable] @{
                                MessageData = $_.Exception.Message
                                CallStack = $this.CallStack
                                ForeGroundColor = "Red"
                                tags = @('MonkeyLog')
                            }
                            Write-Error @msg

                        }
                        Finally{
                            If($lock){
                                #Release lock
                                [System.Threading.Monitor]::Exit($MonkeyLogQueue)
                            }
                        }
                    }
                    $Script:MonkeyLogRunspace.Powershell = [System.Management.Automation.PowerShell]::Create().AddScript($Consumer)
                    $Script:MonkeyLogRunspace.Powershell.Runspace = $Script:MonkeyLogRunspace.Runspace
                    $Script:MonkeyLogRunspace.Handle = $Script:MonkeyLogRunspace.Powershell.BeginInvoke()
                    If(-NOT $_handle.Wait([TimeSpan]::FromSeconds(5))){
                        $msg = [hashtable] @{
                            MessageData = $Script:messages.UnableToStartMessage
                            CallStack = $this.CallStack
                            ForeGroundColor = "Yellow"
                            tags = @('MonkeyLog')
                        }
                        Write-Warning @msg
                        $this.stop()
                    }
                    Else{
                        If($_handle.isSet){
                            $msg = [hashtable] @{
                                MessageData = $Script:messages.LogEnabledMessage
                                InformationAction = $this.informationAction
                                CallStack = $this.CallStack
                                ForeGroundColor = "Green"
                                tags = @('MonkeyLog')
                            }
                            Write-Information @msg
                            $_handle.Dispose()
                            #Set log status
                            $this.isEnabled = $true
                        }
                    }
                }
                Else{
                    $msg = [hashtable] @{
                        MessageData = $Script:messages.BlockingCollectionNotFound
                        InformationAction = $this.informationAction
                        CallStack = $this.CallStack
                        ForeGroundColor = "Yellow"
                        tags = @('MonkeyLog')
                    }
                    Write-Warning @msg
                }
            }
            #Add stop method
            $logger | Add-Member -Type ScriptMethod -Name stop -Value {
                $msg = [hashtable] @{
                    MessageData = $Script:messages.StopLoggerMessage
                    InformationAction = $this.informationAction
                    CallStack = $this.CallStack
                    ForeGroundColor = "Green"
                    tags = @('MonkeyLog')
                }
                Write-Information @msg
                #Check If log is stopped
                If($this.isEnabled -eq $false){
                    $msg = [hashtable] @{
                        MessageData = $Script:messages.AlreadyStoppedMessage
                        InformationAction = $this.informationAction
                        CallStack = $this.CallStack
                        ForeGroundColor = "Green"
                        tags = @('MonkeyLog')
                    }
                    Write-Information @msg
                    return
                }
                #Set log disabled
                $this.isEnabled = $false
                $msg = [hashtable] @{
                    MessageData = $Script:messages.LogStoppedMessage
                    InformationAction = $this.informationAction
                    CallStack = $this.CallStack
                    ForeGroundColor = "Green"
                    tags = @('MonkeyLog')
                }
                Write-Information @msg
                #Finishing adding messages
                Wait-MonkeyLogger
                #Dispose Queue
                $MonkeyLogQueue.CompleteAdding();
                $MonkeyLogQueue.Dispose();
                <#
                If($MonkeyLogQueue.IsAddingCompleted -eq $true){
                    $MonkeyLogQueue.Dispose();
                }
                #>
                [void] $Script:MonkeyLogRunspace.Powershell.EndInvoke($Script:MonkeyLogRunspace.Handle)
                [void] $Script:MonkeyLogRunspace.Powershell.Dispose()
                #Closing runspace
                [void] $Script:MonkeyLogRunspace.Runspace.Dispose();
                #Remove environment variables
                Remove-Variable -Scope Script -Force -Name MonkeyLogQueue -ErrorAction SilentlyContinue
                Remove-Variable -Scope Script -Force -Name MonkeyLogRunspace -ErrorAction Ignore
                Remove-Variable -Scope Script -Force -Name _handle -ErrorAction Ignore
                Remove-Variable -Scope Script -Force -Name enabledLoggers -ErrorAction Ignore
                Remove-Variable -Scope Script -Force -Name monkeyloggerinfoAction -ErrorAction Ignore
                Remove-Variable -Scope Script -Force -Name informationAction -ErrorAction Ignore
                Remove-Variable -Scope Script -Force -Name Debug -ErrorAction Ignore
                Remove-Variable -Scope Script -Force -Name Verbose -ErrorAction Ignore
                Remove-Variable -Scope Script -Force -Name monkeyLogger -ErrorAction Ignore
            }
            #Set variable
            New-Variable -Name monkeyLogger -Scope Script -Option ReadOnly -Value $logger -Force
        }
    }
    Catch{
        Write-Error $_.Exception
    }
}