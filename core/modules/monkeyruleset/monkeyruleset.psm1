Set-StrictMode -Version 1.0

$listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}" -f $PSScriptRoot),"*.ps1","AllDirectories")
$all_files = $listofFiles.Where({($_ -like "*public*") -or ($_ -like "*private*")})
$all_files.ForEach({. $_})

$LocalizedDataParams = @{
    BindingVariable = 'messages';
    BaseDirectory = "{0}/{1}" -f $PSScriptRoot, "Localized";
}
#Import localized data
Import-LocalizedData @LocalizedDataParams;