Set-StrictMode -Version Latest

$monkeyAstPath = ("{0}/public" -f $PSScriptRoot)

$monkeyFiles = Get-ChildItem -Path $monkeyAstPath -Recurse -File -Include "*.ps1"

foreach($monkeyFile in $monkeyFiles){
    . $monkeyFile.FullName
}