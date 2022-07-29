Set-StrictMode -Version Latest

Function Import-MonkeyExcelLib{
    $monkeyExcelPath = ("{0}/lib/Microsoft.Office.Interop.Excel.dll" -f $PSScriptRoot)
    try{
        #Load Excel lib
        [ref]$null = [System.Reflection.Assembly]::Load([IO.File]::ReadAllBytes($monkeyExcelPath))
        Write-Verbose -Message $Script:messages.ExcelLibLoadedSuccessfully
    }
    catch{
        #unable to load Excel Library
        Write-Warning -Message ($Script:messages.UnableToLoadExcelLibrary -f $monkeyExcelPath);
    }
}

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

$script:messages = Get-LocalizedData -DefaultUICulture 'en-US'
#Load Excel Lib
Import-MonkeyExcelLib