[CmdletBinding()]
param ()
$exo_session = $compliance_session = $null
$isO365Object = Get-Variable -Name O365Object -ErrorAction Ignore
$isLoggerPresent = Get-Command -Name Initialize-MonkeyLogger -ErrorAction Ignore
if($null -ne $isO365Object -and $null -ne $isLoggerPresent){
    $progresspreference_backup = $progresspreference;
    $progresspreference='SilentlyContinue'
    $msg = @{
        MessageData = "Importing Logger within runspace";
        callStack = (Get-PSCallStack | Select-Object -First 1);
        logLevel = 'info';
        InformationAction = $O365Object.InformationAction;
        Tags = @('InitializeMonkeyLogger');
    }
    Write-Information @msg
    #Initialize logger
    Initialize-MonkeyLogger
    #Import Localized data
    $LocalizedDataParams = $O365Object.LocalizedDataParams
    if($null -ne $LocalizedDataParams){
        #Import Localized data
        $msg = @{
            MessageData = "Importing localized messages within runspace";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('InitializeLocalizedData');
        }
        Write-Information @msg
        Import-LocalizedData @LocalizedDataParams;
    }
    #Import Exchange Online PsSession
    if($null -ne ($O365Object.o365_sessions.GetEnumerator() | Where-Object {$_.Name -eq 'ExchangeOnline'})){
        $exo_session = $O365Object.o365_sessions.ExchangeOnline
    }
    if($null -ne $exo_session -and $exo_session -is [System.Management.Automation.Runspaces.PSSession]){
        $msg = @{
            MessageData = "Importing Exchange Online PsSession within runspace";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $script:InformationAction;
            Tags = @('InitializeLocalizedData');
        }
        Write-Information @msg
        $p = @{
            Session = $exo_session;
            Prefix = "ExoMonkey";
            DisableNameChecking = $true;
            AllowClobber= $true;
        }
        [ref]$null = Import-PSSession @p
    }
    #Import Exchange Online Compliance PsSession
    if($null -ne ($O365Object.o365_sessions.GetEnumerator() | Where-Object {$_.Name -eq 'ComplianceCenter'})){
        $compliance_session = $O365Object.o365_sessions.ComplianceCenter
    }
    if($null -ne $compliance_session -and $compliance_session -is [System.Management.Automation.Runspaces.PSSession]){
        $msg = @{
            MessageData = "Importing Exchange Online Compliance Center PsSession within runspace";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $script:InformationAction;
            Tags = @('InitializeLocalizedData');
        }
        Write-Information @msg
        $p = @{
            Session = $compliance_session;
            DisableNameChecking = $true;
            AllowClobber= $true;
        }
        [ref]$null = Import-PSSession @p
    }
    #Return old progress preference
    $progresspreference = $progresspreference_backup;
}


