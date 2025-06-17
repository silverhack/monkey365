#Set-StrictMode -Off #-Version Latest
Set-StrictMode -Version Latest

$LocalizedDataParams = @{
    BindingVariable = 'message';
    FileName = 'localized.psd1';
    BaseDirectory = "{0}/{1}" -f $PSScriptRoot, "core/utils";
}
#Import localized data
Import-LocalizedData @LocalizedDataParams;

$msal_modules = @(
    'core/modules/monkeycloudutils'
)
$msal_modules.ForEach({Import-Module ("{0}{1}{2}" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar, $_.ToString()) -Scope Global -Force})

$internal_modules = @(
    'core/modules/monkeylogger',
    'core/modules/monkeyutils',
    'core/modules/monkeyhttpwebrequest'
    'core/modules/psmarkdig',
    'core/modules/monkeyhtml',
    'core/modules/monkeyjob',
    'core/modules/monkeyruleset',
    'core/modules/psocsf',
    'core/modules/monkeyoutput'
)
$internal_modules.ForEach({Import-Module ("{0}{1}{2}" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar, $_.ToString()) -Force})

New-Variable -Name ScriptPath -Value $PSScriptRoot -Scope Script -Force

#Get Azure plugins
$cmds = [System.IO.Directory]::EnumerateFiles(("{0}/core/collector" -f $PSScriptRoot),"*.ps1",[System.IO.SearchOption]::AllDirectories)
$modules = @(
    ("{0}/core/modules/monkeyutils" -f $PSScriptRoot)
)
$p = @{
    ScriptBlock = {Get-MonkeySupportedService -Azure};
    ImportCommands = $cmds;
    ImportModules = $modules;
    ImportVariables = @{"ScriptPath" = $PSScriptRoot};
}
[void](Start-MonkeyJob @p)
Get-MonkeyJob | Wait-MonkeyJob
$azure_plugins = Get-MonkeyJob | Receive-MonkeyJob
#Remove Job
Get-MonkeyJob | Remove-MonkeyJob
New-Variable -Name azure_plugins -Value $azure_plugins -Scope Script -Force
#Get Microsoft 365 plugins
$p = @{
    ScriptBlock = {Get-MonkeySupportedService -Microsoft365};
    ImportModules = $modules;
    ImportCommands = $cmds;
    ImportVariables = @{"ScriptPath" = $PSScriptRoot};
}
[void](Start-MonkeyJob @p)
Get-MonkeyJob | Wait-MonkeyJob
$m365_plugins = Get-MonkeyJob | Receive-MonkeyJob
New-Variable -Name m365_plugins -Value $m365_plugins -Scope Script -Force
#Remove Job
Get-MonkeyJob | Remove-MonkeyJob

$internal_functions = @(
    '/core/init',
    '/core/utils',
    '/core/collector',
    '/core/api/auth',
    '/core/html',
    '/core/tasks',
    '/core/analysis',
    '/core/import',
    '/core/output',
    '/core/watcher',
    '/core/api/EntraID/msgraph',
    '/core/tenant',
    '/core/subscription',
    '/core/api/azure',
    '/core/api/EntraID/graph/api',
    '/core/api/EntraID/graph/helpers/user',
    '/core/api/azure/resourcemanagement/api',
    '/core/api/azure/resourcemanagement/helpers/tenant',
    '/core/api/m365/MicrosoftTeams/',
    '/core/api/m365/ExchangeOnline/'
    '/core/api/m365/SharePointOnline/',
    '/core/api/m365/M365AdminPortal/'
)

$all_files = $internal_functions.ForEach({
    If([System.IO.Directory]::Exists(("{0}{1}" -f $PSScriptRoot,$_))){
        [System.IO.Directory]::EnumerateFiles(("{0}{1}" -f $PSScriptRoot,$_),"*.ps1",[System.IO.SearchOption]::AllDirectories)
    }
})
$all_files = $all_files.Where({$_.EndsWith('ps1')})
$all_files.ForEach({. $_})

$monkey = ("{0}/Invoke-Monkey365.ps1" -f $PSScriptRoot)
. $monkey
