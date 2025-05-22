param(
    [parameter(Position=0,Mandatory=$false)][Object[]]$ForceDesktop
)
Set-StrictMode -Version Latest

if ($PSVersionTable.PSVersion.Major -lt 6.0) {
    switch ($([System.Environment]::OSVersion.Platform)) {
        'Win32NT' {
            New-Variable -Option Constant -Name IsWindows -Value $True -ErrorAction SilentlyContinue
            New-Variable -Option Constant -Name IsLinux -Value $false -ErrorAction SilentlyContinue
            New-Variable -Option Constant -Name IsMacOs -Value $false -ErrorAction SilentlyContinue
        }
    }
}
$Script:IsLinuxEnvironment = (Get-Variable -Name "IsLinux" -ErrorAction Ignore) -and $IsLinux
$Script:IsMacOSEnvironment = (Get-Variable -Name "IsMacOS" -ErrorAction Ignore) -and $IsMacOS
$Script:IsWindowsEnvironment = !$IsLinuxEnvironment -and !$IsMacOSEnvironment

Function Get-CoreLib(){
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

Function Get-DeskLibForCore(){
    try{
        $MsalLibPath = ("{0}{1}lib{2}desktop" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
        $files = [System.IO.Directory]::EnumerateFiles($MsalLibPath,"*.dll","AllDirectories")
        #Remove diagnostic source
        $files = @($files).Where({$_ -notlike '*System.Diagnostics.DiagnosticSource*'})
        #Load .net core path
        $MsalLibPath = ("{0}{1}lib{2}netcore" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
        $ds = [System.IO.Directory]::EnumerateFiles($MsalLibPath,"*System.Diagnostics.DiagnosticSource.dll","AllDirectories")
        $files+=$ds
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

Function Get-DesktopLib(){
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
    try{
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
    Catch{
        Write-Error $_
        throw ("Unable to load MSAL library")
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
        $AssembliesExists = Get-CoreLib
        if($AssembliesExists){
            Install-MsalLibrary
        }
    }
    ElseIf ($PSVersionTable.PSEdition -eq 'Desktop'){
        Write-Verbose ($script:messages.OSVersionMessage -f "Windows", "Desktop")
        $AssembliesExists = Get-DesktopLib
        if($AssembliesExists){
            Install-MsalLibrary
        }
    }
    ElseIf (($PSVersionTable.PSEdition -eq 'Core') -and $Script:IsLinuxEnvironment){
        Write-Verbose ($script:messages.OSVersionMessage -f "Unix", "Core")
        $AssembliesExists = Get-CoreLib
        if($AssembliesExists){
            Install-MsalLibrary
        }
    }
    ElseIf (($PSVersionTable.PSEdition -eq 'Core') -and $Script:IsWindowsEnvironment){
        if($ForceDesktop){
            $AssembliesExists = Get-DeskLibForCore
            if($AssembliesExists){
                Install-MsalLibrary
            }
        }
        else{
            Write-Verbose ($script:messages.OSVersionMessage -f "Windows", "Core")
            $AssembliesExists = Get-CoreLib
            if($AssembliesExists){
                Install-MsalLibrary
            }
        }
    }
    Else{
        Write-Warning -Message 'Unable to determine if OS is Windows or Linux. Loading MSAL Core'
        $AssembliesExists = Get-CoreLib
        if($AssembliesExists){
            Install-MsalLibrary
        }
    }
}
Else{
    Write-Warning -Message 'Unable to determine if OS is Windows or Linux. Loading MSAL Core'
    $AssembliesExists = Get-CoreLib
    if($AssembliesExists){
        Install-MsalLibrary
    }
}

