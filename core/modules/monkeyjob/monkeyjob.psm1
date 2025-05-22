Set-StrictMode -Version Latest

$mj_path = ("{0}/helpers/MonkeyJob.cs" -f $PSScriptRoot)
$exists = [System.IO.File]::Exists($mj_path)
#$mj_helper = Get-ChildItem -Path $mj_path | Where-Object {$_.Extension -in ".cs"} | Select-Object FullName -ErrorAction Ignore
if($exists){
    #Import MonkeyJob helper
    if (-not ([System.Management.Automation.PSTypeName]'MonkeyJob').Type){
        $params = @{
            LiteralPath = $mj_path;
            IgnoreWarnings = $true;
            WarningVariable = "warnVar";
            WarningAction = "SilentlyContinue"
        }
        Add-Type @params
    }
    #Loading internal functions
    $listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}" -f $PSScriptRoot),"*.ps1","AllDirectories")
    $all_files = $listofFiles.Where({($_ -like "*public*") -or ($_ -like "*private*")})
    $content = $all_files.ForEach({
        [System.IO.File]::ReadAllText($_, [Text.Encoding]::UTF8) + [Environment]::NewLine
    })

    #Set-Content -Path $tmpFile -Value $content
    . ([scriptblock]::Create($content))
    $LocalizedDataParams = @{
        BindingVariable = 'messages';
        BaseDirectory = "{0}/{1}" -f $PSScriptRoot, "Localized";
    }
    #Import localized data
    Import-LocalizedData @LocalizedDataParams;
    #Set JobErrors var
    $JobErrors = [System.Collections.Generic.List[System.Object]]::new()
    Set-Variable MonkeyJobErrors -Value $JobErrors -Scope Script -Force
    #Set Monkeyjobs variable
    $MonkeyJobs = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
    Set-Variable MonkeyJobs -Value $MonkeyJobs -Scope Script -Force
    #Set runspacePools list
    $MonkeyRSP = [System.Collections.Generic.List[System.Management.Automation.Runspaces.RunspacePool]]::new()
    Set-Variable MonkeyRSP -Value $MonkeyRSP -Scope Script -Force
    #Set MessageData
    New-Variable MonkeyJobCleanup -Value ([hashtable]::Synchronized(@{})) -Option ReadOnly -Scope Global -Force
    $MonkeyJobCleanup.Flag=$True
    $MonkeyJobCleanup.Host = $Host
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

    $MonkeyJobCleanup.Runspace =[runspacefactory]::CreateRunspace($Host,$InitialSessionState)
    $MonkeyJobCleanup.Runspace.Open()
    $MonkeyJobCleanup.Runspace.SessionStateProxy.SetVariable("MonkeyJobCleanup",$MonkeyJobCleanup)
    $MonkeyJobCleanup.Runspace.SessionStateProxy.SetVariable("MonkeyJobs",$MonkeyJobs)
    $MonkeyJobCleanup.Runspace.SessionStateProxy.SetVariable("MonkeyRSP",$MonkeyRSP)
    $MonkeyJobCleanup.PowerShell = [PowerShell]::Create().AddScript({
        Do{
            If ($MonkeyJobs.Count -gt 0) {
                [System.Threading.Monitor]::Enter($MonkeyJobs.syncroot)
                try{
                    foreach($MonkeyJob in $MonkeyJobs.GetEnumerator()){
                        Write-Verbose ("Cleaning MonkeyJob {0}" -f $MonkeyJob.Name)
                        #Clean MonkeyJob object
                        $MonkeyJob.Job.InnerJob.Stop();
                        $MonkeyJob.Job.InnerJob.Dispose();
                        $MonkeyJob.Job.StopJob();
                        Start-Sleep -Milliseconds 500
                        $MonkeyJob.Job.Dispose();
                        $MonkeyJob.Task.Dispose();
                        $MonkeyJob.Task = $null;
                        #Perform garbage collection
                        [gc]::Collect()
                    }
                }
                catch{
                    Write-Verbose $_
                }
                finally {
                    [System.Threading.Monitor]::Exit($MonkeyJobs.syncroot)
                }
            }
            #Remove runspacepools
            If ($MonkeyRSP.Count -gt 0) {
                [System.Threading.Monitor]::Enter($MonkeyRSP.syncroot)
                try{
                    foreach($RunspacePool in $MonkeyRSP.GetEnumerator()){
                        Write-Verbose ("Cleaning RunspacePool {0}" -f $RunspacePool.InstanceId)
                        $RunspacePool.Close();
                        $RunspacePool.Dispose();
                        #Perform garbage collection
                        [gc]::Collect()
                    }
                }
                catch{
                    Write-Verbose $_
                }
                finally {
                    [System.Threading.Monitor]::Exit($MonkeyRSP.syncroot)
                }
            }
        } while ($MonkeyJobCleanup.Flag)
    })
    #region Handle Module Removal
    $objectEventArgs = {
        $MonkeyJobCleanup.Flag=$False
        $MonkeyJobCleanup.PowerShell.Runspace = $MonkeyJobCleanup.Runspace
        $MonkeyJobCleanup.Handle = $MonkeyJobCleanup.PowerShell.BeginInvoke()
        [System.Threading.WaitHandle]::WaitAll($MonkeyJobCleanup.Handle.AsyncWaitHandle)
        $MonkeyJobCleanup.PowerShell.EndInvoke($MonkeyJobCleanup.Handle)
        $MonkeyJobCleanup.PowerShell.Dispose()
        $MonkeyJobs.Clear()
        $MonkeyRSP.Clear()
    }
    $ExecutionContext.SessionState.Module.OnRemove += $objectEventArgs
    Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $objectEventArgs
    #endregion Handle Module Removal
}
else{
    Write-Warning "Unable to load [MonkeyJob]. PowerShell module was not loaded"
    return
}
