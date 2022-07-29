Set-StrictMode -Version Latest

Function Import-MarkDigLibrary{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param()
    $installed = $false
    $Assemblies = [System.Collections.Generic.List[string]]::new()
    $MarkDigPath = ("{0}/lib" -f $PSScriptRoot)
    ## Select the correct assemblies
    if ($PSEdition -eq 'Desktop'){
        $files = Get-ChildItem -Path ("{0}/net40" -f $MarkDigPath) | Where-Object {$_.Extension -in ".dll"} | Select-Object FullName -ErrorAction SilentlyContinue
        if($null -ne $files){
            foreach ($file in $files) {
                $Assemblies.Add($file.FullName)
            }
        }
    }
    elseif ($PSEdition -eq 'Core'){
        $files = Get-ChildItem -Path ("{0}/netcoreapp2.1" -f $MarkDigPath) | Where-Object {$_.Extension -in ".dll"} | Select-Object FullName -ErrorAction SilentlyContinue
        if($null -ne $files){
            foreach ($file in $files) {
                $Assemblies.Add($file.FullName)
            }
        }
    }
    else{
        Write-Warning "Unknown PowerShell version"
    }
    #Load markdig lib
    try {
        Add-Type -LiteralPath $Assemblies | Out-Null
        Write-Verbose -Message "Markdig library installed successfully"
        $installed = $true
        return $installed
    }
    catch { throw }
}

$isInstalled = Import-MarkDigLibrary

$localizedFnc = ("{0}/private/Get-LocalizedData.ps1" -f $PSScriptRoot)
$fnc = Get-ChildItem -Path $localizedFnc -File
if($fnc -and $isInstalled){
    #Dot source script file
    . $fnc.FullName
    #Load messages
    $script:messages = Get-LocalizedData -DefaultUICulture 'en-US'
    $installed = $true;
    #Check if ADAL is loaded
    if($installed -eq $true){
        $PublicPath = ("{0}/public" -f $PSScriptRoot)
        $PrivatePath = ("{0}/private" -f $PSScriptRoot)
        #Load public files
        $PublicFiles = Get-ChildItem -Path $PublicPath -Recurse -File -Include "*.ps1"
        foreach($_f in $PublicFiles){
            . $_f.FullName
        }
        #Load private files
        $PrivateFiles = Get-ChildItem -Path $PrivatePath -Recurse -File -Include "*.ps1"
        foreach($_f in $PrivateFiles){
            . $_f.FullName
        }
    }
    else{
        Write-Warning "Unable to load psmarkdig module"
    }
}
else{
    Write-Warning "Unable to load psmarkdig module"
}