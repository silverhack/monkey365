Set-StrictMode -Version Latest

if (-not ([System.Management.Automation.PSTypeName]'System.Net.Http.HttpClientHandler').Type){
    Add-Type -AssemblyName System.Net.Http
}

$listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}" -f $PSScriptRoot),"*.ps1","AllDirectories")
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
