[CmdletBinding()]
param ()
$isO365Object = Get-Variable -Name O365Object -ErrorAction Ignore
$isLoggerPresent = Get-Command -Name Initialize-MonkeyLogger -ErrorAction Ignore
if($null -ne $isO365Object -and $null -ne $isLoggerPresent){
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
        Import-LocalizedData @LocalizedDataParams;
    }
    #set the default connection limit
    [System.Net.ServicePointManager]::DefaultConnectionLimit = 1024;
    [System.Net.ServicePointManager]::MaxServicePoints = 1000;
}


