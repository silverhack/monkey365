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
        $files = [System.IO.Directory]::EnumerateFiles(("{0}/net461" -f $MarkDigPath), "*.dll","AllDirectories")
        if($null -ne $files){
            foreach ($file in $files) {
                $Assemblies.Add($file)
            }
        }
    }
    elseif ($PSEdition -eq 'Core'){
        $files = [System.IO.Directory]::EnumerateFiles(("{0}/net8.0" -f $MarkDigPath),"*.dll","AllDirectories")
        if($null -ne $files){
            foreach ($file in $files) {
                $Assemblies.Add($file)
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

if($isInstalled){
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
}
else{
    Write-Warning "Unable to load psmarkdig module"
}
