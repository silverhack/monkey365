Set-StrictMode -Version Latest #-Version 1.0

#Import monkey utils
$modulesRoot = Split-Path -Parent $PSScriptRoot
$monkeyutils = Join-Path $modulesRoot 'monkeyutils/monkeyutils.psd1'
If (-not (Get-Module -Name 'monkeyutils')) {
    Import-Module $monkeyutils
}

#Import psmarkdig module
$markdownPsModule = Join-Path $modulesRoot 'psmarkdig/psmarkdig.psd1'
If (-not (Get-Module -Name 'psmarkdig')) {
    Import-Module $markdownPsModule
}

# Import localized data
$LocalizedDataParams = @{
    BindingVariable = 'messages';
    BaseDirectory = (Join-Path $PSScriptRoot 'Localized');
}
#Import localized data
Import-LocalizedData @LocalizedDataParams;

#Import public and private files
$sourceFolders = @('private', 'public')
ForEach ($folder in $sourceFolders) {
    $path = Join-Path $PSScriptRoot $folder
    If (-not (Test-Path $path)) {
        continue
    }
    $files = [System.IO.Directory]::EnumerateFiles($path,'*',[System.IO.SearchOption]::AllDirectories)
    ForEach ($file in ($files | Sort-Object)) {
        If ([System.IO.Path]::GetExtension($file) -ne '.ps1') {
            continue
        }
        . $file
    }
}
