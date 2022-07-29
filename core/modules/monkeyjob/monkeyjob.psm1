Set-StrictMode -Version Latest

$monkeyJobPublicPath = ("{0}/public" -f $PSScriptRoot)

$monkeyJobPrivatePath = ("{0}/private" -f $PSScriptRoot)

#Load public files
$monkeyFiles = Get-ChildItem -Path $monkeyJobPublicPath -Recurse -File -Include "*.ps1"

foreach($monkeyFile in $monkeyFiles){
    . $monkeyFile.FullName
}

#Load private files
$monkeyFiles = Get-ChildItem -Path $monkeyJobPrivatePath -Recurse -File -Include "*.ps1"

foreach($monkeyFile in $monkeyFiles){
    . $monkeyFile.FullName
}

$script:messages = Get-LocalizedData -DefaultUICulture 'en-US'

#Set JobErrors var
Set-Variable AllJobErrors -Value @() -Scope Script -Force