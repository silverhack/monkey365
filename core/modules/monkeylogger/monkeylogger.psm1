Set-StrictMode -Version Latest

$Modules = @{
    engine = '/core/engine'
    runspaces_helpers = '/core/runspaces'
    console_helper = '/core/helpers'
}

foreach($module in $Modules.GetEnumerator()){
    $loggerPath = ("{0}/{1}" -f $PSScriptRoot,$module.value)
    #Load public files
    $LoggerFiles = Get-ChildItem -Path $loggerPath -Recurse -File -Include "*.ps1"
    foreach($loggerFile in $LoggerFiles){
        Write-Verbose ("Trying to load {0} module" -f $loggerFile.FullName)
        . $loggerFile.FullName
    }
}

#Load proxy functions
$monkeyProxyFunctions = Get-ChildItem -Path ("{0}/core/console" -f $PSScriptRoot) -Recurse -File -Include "*.ps1"
foreach($monkeyFile in $monkeyProxyFunctions){
    . $monkeyFile.FullName
}

Function Start-Logger{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="loggers")]
        [Array]$loggers,

        [parameter(Mandatory= $false, HelpMessage= "Initial path")]
        [String]$InitialPath
    )
    New-Logger @PSBoundParameters
}

Function Stop-Logger{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="Force stop")]
        [Switch]$force
    )
    #Wait messages
    Wait-MonkeyLogger
    if($null -ne (Get-Variable -Name logger -ErrorAction Ignore)){
        if($logger.is_enabled){
            Write-Verbose "Stopping logger"
            $logger.stop()
        }
    }
    #Clean vars
    if($force.IsPresent){
        if($null -ne (Get-Variable -Name LogQueue -ErrorAction Ignore)){
            Remove-Variable -Scope Script -Force -Name LogQueue -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name MonkeyLogRunspace -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name _handle -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name enabled_loggers -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name logger -ErrorAction SilentlyContinue
            Remove-Variable -Scope Script -Force -Name monkeyloggerinfoAction -ErrorAction SilentlyContinue
        }
    }
}