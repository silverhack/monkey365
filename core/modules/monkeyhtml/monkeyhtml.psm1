Set-StrictMode -Version Latest

$monkeyPublicPath = ("{0}/public" -f $PSScriptRoot)

$monkeyPrivatePath = ("{0}/private" -f $PSScriptRoot)

#Load public files
$monkeyFiles = Get-ChildItem -Path $monkeyPublicPath -Recurse -File -Include "*.ps1"

foreach($monkeyFile in $monkeyFiles){
    . $monkeyFile.FullName
}

#Load private files
$monkeyFiles = Get-ChildItem -Path $monkeyPrivatePath -Recurse -File -Include "*.ps1"

foreach($monkeyFile in $monkeyFiles){
    . $monkeyFile.FullName
}

#Force update psobject with GetPropertyByPath
Update-PsObject

$script:messages = Get-LocalizedData -DefaultUICulture 'en-US'