Set-StrictMode -Version Latest

$monkeyPath = ("{0}/public" -f $PSScriptRoot)

$monkeyFiles = Get-ChildItem -Path $monkeyPath -Recurse -File -Include "*.cs"

if($null -ne $monkeyFiles){
    $p = @{
        LiteralPath = $monkeyFiles.FullName;
        IgnoreWarnings = $true;
        WarningVariable = "warnVar";
        WarningAction = "SilentlyContinue"
    }
    Add-Type @p
}