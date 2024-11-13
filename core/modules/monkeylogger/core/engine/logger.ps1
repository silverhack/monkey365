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
        [parameter(ValueFromPipelineByPropertyName=$true, Mandatory= $false, HelpMessage= "Loggers")]
        [Array]$Loggers=@(),

        [parameter(Mandatory= $false, HelpMessage= "Initial path")]
        [String]$InitialPath
    )
    Begin{
        #Check informationAction
        if(-NOT $PSBoundParameters.ContainsKey('informationAction')){
            $PSBoundParameters.Add('informationAction',$InformationPreference);
        }
        #Check Debug
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $verbosity=@{Debug=$true}
            $DebugPreference = 'Continue'
        }
        else{
            $verbosity=@{Debug=$false}
        }
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $verbosity.Add("Verbose",$true)
        }
        else{
            $verbosity.Add("Verbose",$false)
        }
        #Create object
        $logger = New-Object -Type PSObject -Property @{
          path = Split-Path -Path $PSCmdlet.MyInvocation.PSCommandPath -Parent
          CallStack = (Get-PSCallStack | Select-Object -First 1);
          Callers = @()
          is_enabled = $false
          func_definitions = @()
          validation_functions = @()
          helper_functions = @()
          informationAction = $PSBoundParameters.informationAction
          verbosity= $verbosity
          Verbose = $verbosity.Verbose
          Debug = $verbosity.Debug
          DebugPreference = $DebugPreference
          loggers = $Loggers
          enabled_loggers = $null
          rootPath = $null;
          initialPath = $InitialPath
        }
        #Set informationAction, debug and verbose variables
        New-Variable -Name monkeyloggerinfoAction -Scope Script -Value $PSBoundParameters.informationAction -Force
        #New-Variable -Name informationAction -Scope Script -Value $informationAction -Force
        New-Variable -Name Debug -Scope Script -Value $verbosity.Debug -Force
        New-Variable -Name Verbose -Scope Script -Value $verbosity.Verbose -Force
        #Import write-information wrapper function
        #Load configuration
        $logger | Add-Member -Type ScriptMethod -Name loadConf -Value {
            #reset callers array
            $this.Callers = @()
            #Load configuration files
            $conf_path = ("{0}/targets" -f $this.path)
            #$conf_files = Get-ChildItem -Path $conf_path -Filter '*.json'
            $conf_files = [System.IO.Directory]::EnumerateFiles($conf_path,"*.json",[System.IO.SearchOption]::TopDirectoryOnly)
            foreach($conf_file in $conf_files){
                $this.Callers += (Get-Content $conf_file -Raw) | ConvertFrom-Json
            }
            #Load output scripts
            $conf_path = ("{0}/output" -f $this.path)
            $output_callers = [System.IO.Directory]::EnumerateFiles($conf_path,"*.ps1",[System.IO.SearchOption]::TopDirectoryOnly)
            #$output_callers = Get-ChildItem -Path $conf_path -Filter '*.ps1'
            if($null -ne $output_callers){
                #$this.func_definitions = Get-AstFunctionsFromFile -Files $output_callers
                $this.func_definitions = Get-AstFunction -Objects $output_callers
            }
            #Add validation functions
            $validators_path = ("{0}/core/init" -f $this.path)
            $validator_functions = [System.IO.Directory]::EnumerateFiles($validators_path,"*.ps1",[System.IO.SearchOption]::TopDirectoryOnly)
            #$validator_functions = Get-ChildItem -Path $validators_path -Filter '*.ps1'
            if($null -ne $validator_functions){
                #$this.validation_functions = Get-AstFunctionsFromFile -Files $validator_functions
                $this.validation_functions = Get-AstFunction -Objects $validator_functions
            }
            #Add helpers functions
            $helpers_path = ("{0}/core/helpers" -f $this.path)
            $helpers_functions = [System.IO.Directory]::EnumerateFiles($helpers_path,"*.ps1",[System.IO.SearchOption]::TopDirectoryOnly)
            #$helpers_functions = Get-ChildItem -Path $helpers_path -Filter '*.ps1'
            if($null -ne $helpers_functions){
                #$this.helper_functions = Get-AstFunctionsFromFile -Files $helpers_functions
                $this.helper_functions = Get-AstFunction -Objects $helpers_functions
            }
        }
        #Add init loggers method
        $logger | Add-Member -Type ScriptMethod -Name init_loggers -Value {
            $enabled_loggers = @()
            try{
                $msg = [hashtable] @{
                    MessageData = "Initializing loggers"
                    InformationAction = $this.informationAction
                    CallStack = $logger.CallStack
                    ForeGroundColor = "Green"
                    tags = @('MonkeyLog')
                }
                Write-Information @msg
                foreach($new_logger in $this.loggers.GetEnumerator()){
                    #Check if should validate conf
                    Try{
                        $should_validate = @($this.Callers).Where({$null -ne $_ -and $_.name -eq $new_logger.type}) | `
                                                 Select-Object -ExpandProperty validate `
                                                 -ErrorAction SilentlyContinue
                        If($null -ne $should_validate){
                            $_function = @($logger.validation_functions).Where({$null -ne $_ -and $_.Name -eq $should_validate})
                            If($_function.Count -gt 0){
                                $validate_function = $_function.Body.GetScriptBlock()
                            }
                        }
                        If($new_logger.configuration -and $null -ne $validate_function){
                            $config = Initialize-Configuration -Configuration $new_logger.configuration
                            if($null -ne $config){
                                $status = Invoke-Command -ScriptBlock $validate_function -ArgumentList $config
                                if($status -eq $false){
                                    continue;
                                }
                            }
                        }
                        $internal_func = @($this.Callers).Where({$_.name -eq $new_logger.type}) | Select-Object -ExpandProperty function
                        #check if internal function exists
                        $exists = @($this.func_definitions).Where({$_.name -eq $internal_func})
                        If($internal_func -and $exists.Count -gt 0){
                            $new_logger | Add-Member -Type NoteProperty -name function -value $internal_func -Force
                            $enabled_loggers+=$new_logger
                        }
                    }
                    Catch{
                        $msg = [hashtable] @{
                            MessageData = $_.Exception.Message
                            InformationAction = $this.informationAction
                            CallStack = $this.CallStack
                            ForeGroundColor = "Red"
                            tags = @('MonkeyLog')
                        }
                        Write-Debug @msg
                    }
                }
            }
            catch{
                $msg = [hashtable] @{
                    Message = $_
                    InformationAction = $this.informationAction
                    CallStack = $this.CallStack
                    ForeGroundColor = "Yellow"
                    tags = @('MonkeyLog')
                }
                Write-Error @msg
            }
            #Add enabled loggers
            $this.enabled_loggers = $enabled_loggers
        }
        #Add init method
        $logger | Add-Member -Type ScriptMethod -Name init -Value {
            #Check if log is enabled
            if($this.is_enabled){
                $msg = [hashtable] @{
                    MessageData = "Log is already configured and active"
                    InformationAction = $this.informationAction
                    CallStack = $this.CallStack
                    ForeGroundColor = "Yellow"
                    tags = @('MonkeyLog')
                }
                Write-Information @msg
                return
            }
            #Initialize vars
            if($null -eq (Get-Variable -Name LogQueue -ErrorAction Ignore)){
                New-Variable -Name LogQueue -Scope Global `
                                -Value ([System.Collections.Concurrent.BlockingCollection[System.Management.Automation.InformationRecord]]::new(100)) -Force
            }
            New-Variable -Name MonkeyLogRunspace -Scope Script -Option ReadOnly `
                         -Value ([hashtable]::Synchronized(@{ })) -Force
            New-Variable -Name _handle -Scope Script -Option ReadOnly `
                         -Value ([System.Threading.ManualResetEventSlim]::new($false)) -Force
            New-Variable -Name enabled_loggers -Scope Script -Value $this.enabled_loggers -Force

            $session_vars = @{
                "LogQueue"=$LogQueue;
                "_handle"=$_handle;
                "enabled_loggers" = $this.enabled_loggers;
            }
            #
            $Script:InitialSessionState = New-LoggerSessionState -ImportVariables $session_vars -ApartmentState MTA
            #Setup runspace
            $Script:MonkeyLogRunspace.Runspace = [runspacefactory]::CreateRunspace($Host,$Script:InitialSessionState)
            $Script:MonkeyLogRunspace.Runspace.Name = 'Monkey365LogRunspace'
            $Script:MonkeyLogRunspace.Runspace.Open()
            $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('verbosity', $this.verbosity)
            $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('Debug', $this.Debug)
            $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('Verbose', $this.Verbose)
            $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.SetVariable('InformationAction', $this.informationAction)
            #Set location
            if($PSBoundParameters.ContainsKey('InitialPath') -and $PSBoundParameters['InitialPath']){
                $Script:MonkeyLogRunspace.Runspace.SessionStateProxy.Path.SetLocation($InitialPath);
            }
            Try{
                # Add the functions into the runspace
                @($this.func_definitions).Where({$null -ne $_}).Foreach(
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
                    if($null -ne $_fnc){
                        [void]$Script:MonkeyLogRunspace.Runspace.SessionStateProxy.InvokeProvider.Item.Set(
                            'function:\{0}' -f $_fnc.Ast.Name,
                            $_fnc.Ast.Body.GetScriptBlock())
                    }
                }
                # Add helper functions into the runspace
                @($this.helper_functions).Where({$null -ne $_}).Foreach(
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
                try{
                    # Lock LogQueue
                    [System.Threading.Monitor]::Enter($LogQueue)
                    $lock = $true
                    foreach ($Log in $LogQueue.GetConsumingEnumerable()) {
                        if($Log.type -eq '*' -or [string]::IsNullOrEmpty($Log.type)){
                            $enabled_channels = $enabled_loggers
                        }
                        else{
                            #Get channels
                            $enabled_channels = $enabled_loggers | Where-Object {$_.type.ToLower() -in $Log.type.ToLower()}
                        }
                        foreach($channel in $enabled_channels){
                            try{
                                $function = Get-Content ("function:\{0}" -f $channel.function)
                                if($null -ne $function){
                                    $ArgumentList = @{Log=$Log;Configuration=$channel.configuration}
                                    $param = @{
                                        ScriptBlock = {.$function @ArgumentList}
                                    }
                                    Invoke-Command @param
                                }
                            }
                            catch{
                                $msg = [hashtable] @{
                                    MessageData = $_.Exception.Message
                                    InformationAction = $this.informationAction
                                    CallStack = $this.CallStack
                                    ForeGroundColor = "Red"
                                    tags = @('MonkeyLog')
                                }
                                Write-Debug @msg
                            }
                        }
                    }
                }
                catch{
                    $msg = [hashtable] @{
                        MessageData = $_.Exception.Message
                        InformationAction = $this.informationAction
                        CallStack = $this.CallStack
                        ForeGroundColor = "Red"
                        tags = @('MonkeyLog')
                    }
                    Write-Debug @msg

                }
                finally{
                    if($lock){
                        #Release lock
                        [System.Threading.Monitor]::Exit($LogQueue)
                    }
                }
            }
            $Script:MonkeyLogRunspace.Powershell = [System.Management.Automation.PowerShell]::Create().AddScript($Consumer)
            $Script:MonkeyLogRunspace.Powershell.Runspace = $Script:MonkeyLogRunspace.Runspace
            $Script:MonkeyLogRunspace.Handle = $Script:MonkeyLogRunspace.Powershell.BeginInvoke()
            if(-NOT $_handle.Wait([TimeSpan]::FromSeconds(5))){
                $msg = [hashtable] @{
                    MessageData = "Unable to start Log"
                    CallStack = $this.CallStack
                    ForeGroundColor = "Red"
                    tags = @('MonkeyLog')
                }
                Write-Warning @msg
                $this.stop()
            }
            else{
                if($_handle.isSet){
                    $msg = [hashtable] @{
                        MessageData = "Log enabled"
                        InformationAction = $this.informationAction
                        CallStack = $this.CallStack
                        ForeGroundColor = "Green"
                        tags = @('MonkeyLog')
                    }
                    Write-Information @msg
                    $_handle.Dispose()
                    #Set log status
                    $this.is_enabled = $true
                }
            }
        }
        #Add stop method
        $logger | Add-Member -Type ScriptMethod -Name stop -Value {
            $msg = [hashtable] @{
                MessageData = "Stopping loggers"
                InformationAction = $this.informationAction
                CallStack = $this.CallStack
                ForeGroundColor = "Green"
                tags = @('MonkeyLog')
            }
            Write-Information @msg
            #Check if log is stopped
            if($this.is_enabled -eq $false){
                $msg = [hashtable] @{
                    MessageData = "Log is already stopped"
                    InformationAction = $this.informationAction
                    CallStack = $this.CallStack
                    ForeGroundColor = "Yellow"
                    tags = @('MonkeyLog')
                }
                Write-Information @msg
                return
            }
            $LogQueue.CompleteAdding()
            $LogQueue.Dispose()
            [void] $Script:MonkeyLogRunspace.Powershell.EndInvoke($Script:MonkeyLogRunspace.Handle)
            [void] $Script:MonkeyLogRunspace.Powershell.Dispose()
            #Closing runspace
            #[void] $Script:MonkeyLogRunspace.Runspace.Close()
            [void] $Script:MonkeyLogRunspace.Runspace.Dispose()
            #Remove environment variables
            #Remove-Variable -Scope Script -Force -Name LogQueue -ErrorAction SilentlyContinue
            Remove-Variable -Scope Global -Force -Name LogQueue -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name MonkeyLogRunspace -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name _handle -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name enabled_loggers -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name logger -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name monkeyloggerinfoAction -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name informationAction -ErrorAction Ignore
            Remove-Variable -Scope Script -Force -Name Debug -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name Verbose -ErrorAction SilentlyContinue
            #Set log disabled
            $this.is_enabled = $false
            $msg = [hashtable] @{
                MessageData = "Logger stopped"
                InformationAction = $this.informationAction
                CallStack = $this.CallStack
                ForeGroundColor = "Green"
                tags = @('MonkeyLog')
            }
            Write-Information @msg
        }
    }
    Process{
        if($null -eq (Get-Variable -Name LogQueue -ErrorAction Ignore) -or $null -eq (Get-Variable -Name logger -ErrorAction Ignore)){
            #Load configuration
            $logger.loadConf()
            #Initialize loggers
            $logger.init_loggers()
            #Init runspace
            $logger.init()
        }
        else{
            $msg = [hashtable] @{
                MessageData = "Log is already configured and active"
                InformationAction = $logger.informationAction
                CallStack = $logger.CallStack
                ForeGroundColor = "Yellow"
                tags = @('MonkeyLog')
            }
            Write-Warning @msg
        }
    }
    End{
        if($logger.is_enabled){
            Set-Variable logger -Value $logger -Scope Script -Force
            return $true
        }
        else{
            return $null
        }
    }
}
