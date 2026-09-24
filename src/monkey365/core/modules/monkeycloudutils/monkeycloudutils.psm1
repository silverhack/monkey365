Set-StrictMode -Version Latest

#Get public functions
$PublicFolder = Join-Path -Path $PSScriptRoot -ChildPath "public"
$publicFunctions = (Get-ChildItem -Path $PublicFolder -Filter *.ps1 -File).BaseName

#Import monkeymsal
$modulesRoot = Split-Path -Parent $PSScriptRoot
$monkeymsal = Join-Path $modulesRoot 'monkeymsal/monkeymsal.psd1'
If (-not (Get-Module -Name 'monkeymsal')) {
    Import-Module $monkeymsal
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
#Export module members
Export-ModuleMember -Function $publicFunctions
