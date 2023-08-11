Set-StrictMode -Version Latest

Function Install-Core(){
    try{
        $MsalLibPath = ("{0}{1}lib{2}netcore" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
        $files = [System.IO.Directory]::EnumerateFiles($MsalLibPath,"*.dll","AllDirectories")
        if($null -ne $files){
            foreach ($file in $files) {
                $Assemblies.Add($file)
            }
        }
        return $true
    }
    catch{
        return $false
    }
}

Function Install-Desktop(){
    try{
        $MsalLibPath = ("{0}{1}lib{2}desktop" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
        $files = [System.IO.Directory]::EnumerateFiles($MsalLibPath,"*.dll","AllDirectories")
        if($null -ne $files){
            foreach ($file in $files) {
                $Assemblies.Add($file)
            }
        }
        return $true
    }
    catch{
        return $false
    }
}

Function Install-MsalLibrary(){
    $params = @{
        LiteralPath = $Assemblies;
        IgnoreWarnings = $true;
        WarningVariable = "warnVar";
        WarningAction = "SilentlyContinue"
    }
    Add-Type @params | Out-Null
    if ($PSVersionTable.PSVersion -ge [version]'6.0') {
        $Assemblies.Add('System.Console.dll')
    }
    if (-not ([System.Management.Automation.PSTypeName]'DeviceCodeHelper').Type){
        $cs_path = ("{0}/helpers/devicecode.cs" -f $PSScriptRoot)
        $exists = [System.IO.File]::Exists($cs_path)
        if($exists){
            $params = @{
                LiteralPath = $cs_path;
                ReferencedAssemblies = $Assemblies;
                IgnoreWarnings = $true;
                WarningVariable = "warnVar";
                WarningAction = "SilentlyContinue"
            }
            Add-Type @params
        }
        else{
            Write-Verbose "Unable to load [DeviceCodeHelper]"
        }
    }
}

$Assemblies = [System.Collections.Generic.List[string]]::new()
$LocalizedDataParams = @{
    BindingVariable = 'messages';
    BaseDirectory = "{0}/{1}" -f $PSScriptRoot, "Localized";
}
#Import localized data
Import-LocalizedData @LocalizedDataParams;

$listofFiles = [System.IO.Directory]::EnumerateFiles(("{0}" -f $PSScriptRoot),"*.ps1","AllDirectories")
$all_files = $listofFiles.Where({($_ -like "*public*") -or ($_ -like "*private*")})
$content = $all_files.ForEach({
    [System.IO.File]::ReadAllText($_, [Text.Encoding]::UTF8) + [Environment]::NewLine
})

#Set-Content -Path $tmpFile -Value $content
. ([scriptblock]::Create($content))

$osInfo = Get-OsInfo
if($null -ne $osInfo){
    if($osInfo.IsUserInteractive -eq $false){
        Write-Verbose ($script:messages.OSVersionMessage -f "Headless", "Core")
        $isInstalled = Install-Core
        if($isInstalled){
            Install-MsalLibrary
        }
    }
    ElseIf ($PSVersionTable.PSEdition -eq 'Desktop'){
        Write-Verbose ($script:messages.OSVersionMessage -f "Windows", "Desktop")
        $isInstalled = Install-Desktop
        if($isInstalled){
            Install-MsalLibrary
        }
    }
    ElseIf (($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Unix')){
        Write-Verbose ($script:messages.OSVersionMessage -f "Unix", "Core")
        $isInstalled = Install-Core
        if($isInstalled){
            Install-MsalLibrary
        }
    }
    ElseIf (($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Win32NT')){
        Write-Verbose ($script:messages.OSVersionMessage -f "Windows", "Desktop")
        $isInstalled = Install-Desktop
        if($isInstalled){
            Install-MsalLibrary
        }
    }
    Else{
        Write-Warning -Message 'Unable to determine if OS is Windows or Linux. Loading MSAL Desktop'
        $isInstalled = Install-Desktop
        if($isInstalled){
            Install-MsalLibrary
        }
    }
}
