Set-StrictMode -Version Latest

Function Import-MonkeyLibForADAL{
    $installed = $false
    if ($PSEdition -eq 'Core'){
        Write-Warning -Message ($Script:messages.AdalUnsupportedOSErrorMessage -f [System.Environment]::OSVersion.VersionString);
        return $installed;
    }
    else{
        $monkeyADALPath = ("{0}/lib/Microsoft.IdentityModel.Clients.ActiveDirectory.dll" -f $PSScriptRoot)
        try{
            #Load ADAL lib
            [ref]$null = [System.Reflection.Assembly]::Load([IO.File]::ReadAllBytes($monkeyADALPath))
            $installed = $true
            Write-Verbose -Message $Script:messages.ADALLoadedSuccessfully
            return $installed
        }
        catch{
            #unable to load ADAL Library
            Write-Warning -Message ($Script:messages.UnableToLoadAdalLibrary -f $monkeyADALPath);
            $installed = $false
            return $installed
        }
    }
}
$localizedFnc = ("{0}/private/Get-LocalizedData.ps1" -f $PSScriptRoot)
$fnc = Get-ChildItem -Path $localizedFnc -File
if($fnc){
    #Dot source script file
    . $fnc.FullName
    #Load messages
    $script:messages = Get-LocalizedData -DefaultUICulture 'en-US'
    #Load ADAL library
    $adalInstalled = Import-MonkeyLibForADAL
    #Check if ADAL is loaded
    if($adalInstalled -eq $true){
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
    }
    else{
        Write-Warning "Unable to load MonkeyADAL module"
    }
}
else{
    Write-Warning "Unable to load MonkeyADAL module"
}