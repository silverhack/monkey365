Set-StrictMode -Version Latest

$listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}" -f $PSScriptRoot),"*.ps1","AllDirectories")
$all_files = $listofFiles.Where({`
    ($_ -like ("*core{0}engine*" -f [System.IO.Path]::DirectorySeparatorChar)) `
    -or ($_ -like ("*core{0}runspaces*" -f [System.IO.Path]::DirectorySeparatorChar)) `
    -or ($_ -like ("*core{0}helpers*" -f [System.IO.Path]::DirectorySeparatorChar))})
    $content = $all_files.ForEach({
        [System.IO.File]::ReadAllText($_, [Text.Encoding]::UTF8) + [Environment]::NewLine
    })

#Set-Content -Path $tmpFile -Value $content
. ([scriptblock]::Create($content))

#Load proxy functions
$monkeyProxyFunctions = ("{0}/core/console" -f $PSScriptRoot)
$listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}" -f $monkeyProxyFunctions),"*.ps1","AllDirectories")
$content = $listofFiles.ForEach({
    [System.IO.File]::ReadAllText($_, [Text.Encoding]::UTF8) + [Environment]::NewLine
})

#Set-Content -Path $tmpFile -Value $content
. ([scriptblock]::Create($content))

Function Start-Logger{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="loggers")]
        [Array]$loggers,

        [parameter(Mandatory= $false, HelpMessage= "Initial path")]
        [String]$InitialPath,

        [parameter(Mandatory= $false, HelpMessage= "Queue logger")]
        [System.Collections.Concurrent.BlockingCollection`1[System.Management.Automation.InformationRecord]]$LogQueue
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
