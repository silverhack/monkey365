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
        $files = [System.IO.Directory]::EnumerateFiles(("{0}/netstandard2.0" -f $MarkDigPath), "*.dll","AllDirectories")
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
    #Get public functions
    $PublicFolder = Join-Path -Path $PSScriptRoot -ChildPath "public"
    $publicFunctions = (Get-ChildItem -Path $PublicFolder -Filter *.ps1 -File).BaseName
    # Import localized data
    $LocalizedDataParams = @{
        BindingVariable = 'messages';
        BaseDirectory = (Join-Path $PSScriptRoot 'Localized');
    }
    #Import localized data
    Import-LocalizedData @LocalizedDataParams;
    #Import public and private files
    $sourceFolders = @('private', 'public')
    ForEach ($folder in $sourceFolders) {
        $path = Join-Path $PSScriptRoot $folder
        If (-not (Test-Path $path)) {
            continue
        }
        $files = [System.IO.Directory]::EnumerateFiles($path,'*',[System.IO.SearchOption]::AllDirectories)
        ForEach ($file in ($files | Sort-Object)) {
            If ([System.IO.Path]::GetExtension($file) -ne '.ps1') {
                continue
            }
            . $file
        }
    }
    #Export module members
    Export-ModuleMember -Function $publicFunctions
}
else{
    Write-Warning "Unable to load psmarkdig module"
}
