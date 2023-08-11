#Set-StrictMode -Off #-Version Latest
Set-StrictMode -Version Latest

$LocalizedDataParams = @{
    BindingVariable = 'message';
    FileName = 'localized.psd1';
    BaseDirectory = "{0}/{1}" -f $PSScriptRoot, "core/utils";
}
#Import localized data
Import-LocalizedData @LocalizedDataParams;

#msal modules
$msal_modules = @(
    'core/modules/monkeycloudutils',
    'core/modules/monkeymsal',
    'core/modules/monkeymsalauthassistant'
)
$msal_modules.ForEach({Import-Module ("{0}{1}{2}" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar, $_.ToString()) -Scope Global})

$listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}{1}core" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar),"*.ps1","AllDirectories")
$all_files = $listofFiles.Where({$_ -notlike "*modules*" -and $_ -notlike "*runspace_init*"})
$content = $all_files.ForEach({
    [System.IO.File]::ReadAllText($_, [Text.Encoding]::UTF8) + [Environment]::NewLine
})
#Set-Content -Path $tmpFile -Value $content
. ([scriptblock]::Create($content))

New-Variable -Name ScriptPath -Value $PSScriptRoot -Scope Script -Force

#Get Azure plugins
New-Variable -Name azure_plugins -Value (Get-MonkeySupportedService -Azure) -Scope Script -Force
#Get Microsoft 365 plugins
New-Variable -Name m365_plugins -Value (Get-MonkeySupportedService -M365) -Scope Script -Force

#New Object to create UserAgent
if($null -eq (Get-Variable -Name O365Object -Scope Script -ErrorAction Ignore)){
    #Create a new O365 object
    New-O365Object
}

$monkey = ("{0}\Invoke-Monkey365.ps1" -f $PSScriptRoot)
. $monkey