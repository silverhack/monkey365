Set-StrictMode -Version 1.0

<#
$listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}" -f $PSScriptRoot),"*.ps1","AllDirectories").Where({$_.EndsWith('.ps1')})
$all_files = $listofFiles.Where({($_ -like "*public*") -or ($_ -like "*private*")})
$all_files.ForEach({. $_})
#>

$listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}" -f $PSScriptRoot),"*.ps1","AllDirectories").Where({$_.EndsWith('.ps1')})
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

