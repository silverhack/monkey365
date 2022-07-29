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


Function Watch-AccessToken{
    <#
        .SYNOPSIS
		####### Utility that will monitor access tokens lifetime ########

        .DESCRIPTION
		####### Utility that will monitor access tokens lifetime ########

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Watch-AccessToken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory = $false)]
        [String]$SourceIdentifier = "monkey_watcher",

        [Parameter(Mandatory = $false)]
        [Int] $Interval = 15,

        #Attempt to unregister event and stop all jobs.
        [Parameter(Mandatory = $false)]
        [switch] $Stop,

        #Attempt to unregister event and restart all jobs.
        [Parameter(Mandatory = $false)]
        [switch] $Force
    )
    Begin{
        #Check if access tokens
        if($null -ne $O365Object.auth_tokens -and @($O365Object.auth_tokens.GetEnumerator() | Where-Object {$null -ne $_.Value}).count -eq 0){
            $msg = @{
                MessageData = $message.EmptyAccessTokensErrorMessage;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $script:InformationAction;
                Tags = @('MonkeyWatcherEmptyAccessTokens');
            }
            Write-Warning @msg
        }
    }
    Process{
        #Create timer and set timespan
        $Timer = New-Object Timers.Timer
        $timeSpan = New-TimeSpan -Minutes $Interval
        $objectEventArgs = @{
            InputObject = $Timer
            EventName = 'Elapsed'
            SourceIdentifier = $SourceIdentifier
            MessageData = $O365Object
            action = {
                $O365Object = $event.MessageData
                $ScriptPath = $O365Object.Localpath
                #Import modules
                foreach($module in $O365Object.watcher.GetEnumerator()){
                    $metadata = [System.IO.File]::GetAttributes(("{0}/{1}" -f $ScriptPath, $module))
                    if($metadata -eq "Directory"){
                        $all_files = Get-ChildItem -Recurse -Path ("{0}/{1}" -f $ScriptPath, $module) -File -Include "*.ps1" -ErrorAction Ignore
                        if($null -ne $all_files){
                            foreach ($mod in $all_files){
                                Write-Verbose ("Loading {0} module" -f $mod.FullName)
                                . $mod.FullName
                            }
                        }
                    }
                    else{
                        Write-Verbose ("Loading {0} module" -f $module)
                        $tmp_module = ("{0}/{1}" -f $ScriptPath, $module)
                        . $tmp_module.ToString()
                    }
                }
                Invoke-MonkeyRefreshToken -O365Object $O365Object
            }.GetNewClosure()
        }
    }
    End{
        if($Stop){
            $msg = @{
                MessageData = $message.StopMonkeyWatcher;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $script:InformationAction;
                Tags = @('MonkeyWatcherStopMessage');
            }
            Write-Debug @msg
            #Attemp to unregister event
            if(@(Get-EventSubscriber | Where-Object {$_.SourceIdentifier -eq $SourceIdentifier}).count -gt 0){
                $my_event = Get-EventSubscriber | Where-Object {$_.SourceIdentifier -eq $SourceIdentifier}
                [ref]$null = Unregister-Event -SourceIdentifier $SourceIdentifier -Force -ErrorAction Ignore
                #Stop all jobs
                [ref]$null = Get-Job | Where-Object {$_.Name -eq $SourceIdentifier} | Stop-Job
                #Remove all jobs
                [ref]$null = Get-Job | Where-Object {$_.Name -eq $SourceIdentifier} | Remove-Job -Force
                #remove job
                Remove-Job $my_event.SourceIdentifier -Force -ErrorAction Ignore
            }
            return;
        }
        if(@(Get-EventSubscriber | Where-Object {$_.SourceIdentifier -eq $SourceIdentifier}).count -gt 0){
            $my_event = Get-EventSubscriber -SourceIdentifier $SourceIdentifier
            if($my_event.Action.state -eq "Failed"){
                $msg = @{
                    MessageData = $message.MonkeyWatcherErrorMessage;
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    InformationAction = $script:InformationAction;
                    Tags = @('MonkeyWatcherFailedMessage');
                }
                Write-Debug @msg
                $msg = @{
                    MessageData = $my_event.Action.Error;
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    InformationAction = $script:InformationAction;
                    Tags = @('MonkeyWatcherFailedMessage');
                }
                Write-Debug @msg
                #Removing orphan event
                Wait-Event -SourceIdentifier $SourceIdentifier -Timeout 5
                Get-EventSubscriber -SourceIdentifier $SourceIdentifier -Force | Unregister-Event -Force
            }
            else{
                $msg = @{
                    MessageData = $message.MonkeyWatcherAlreadyRunning;
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    InformationAction = $script:InformationAction;
                    Tags = @('MonkeyWatcherStopMessage');
                }
                Write-Debug @msg
                if($Force){
                    $msg = @{
                        MessageData = $message.RestartMonkeyWatchter;
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        InformationAction = $script:InformationAction;
                        Tags = @('MonkeyWatcherStopMessage');
                    }
                    Write-Debug @msg
                    #There are jobs present. Stopping Jobs
                    Watch-AccessToken -SourceIdentifier $SourceIdentifier -Stop
                    #Waiting 5 seconds
                    Start-Sleep -Seconds 5
                    #Start Watcher
                    Watch-AccessToken -SourceIdentifier $SourceIdentifier -Interval $Interval
                }
            }
        }
        else{
            #Start
            $msg = @{
                MessageData = $message.StartMonkeyWatcher;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $script:InformationAction;
                Tags = @('MonkeyWatcherStartMessage');
            }
            Write-Debug @msg
            #Start Watcher
            [ref]$null = Register-ObjectEvent @objectEventArgs
            $Timer.Interval = $timeSpan.TotalMilliseconds
            $Timer.Autoreset = $True
            $Timer.Enabled = $True
            $msg = @{
                MessageData = $message.MonkeyWatcherStartSuccess;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $script:InformationAction;
                Tags = @('MonkeyWatcherStartMessage');
            }
            Write-Debug @msg
        }
    }
}
