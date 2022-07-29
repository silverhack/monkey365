Set-StrictMode -Version Latest

Function Import-MonkeyMSALLib{
    $installed = $false
    $Assemblies = [System.Collections.Generic.List[string]]::new()
    $monkeyMSALPath = ("{0}/lib" -f $PSScriptRoot)
    ## Select the correct assemblies
    if ($PSEdition -eq 'Desktop'){
        $files = Get-ChildItem -Path ("{0}/desktop" -f $monkeyMSALPath) | Where-Object {$_.Extension -in ".dll"} | Select-Object FullName -ErrorAction SilentlyContinue
        if($null -ne $files){
            foreach ($file in $files) {
                $Assemblies.Add($file.FullName)
            }
        }
    }
    elseif ($PSEdition -eq 'Core'){
        $files = Get-ChildItem -Path ("{0}/netcore" -f $monkeyMSALPath) | Where-Object {$_.Extension -in ".dll"} | Select-Object FullName -ErrorAction SilentlyContinue
        if($null -ne $files){
            foreach ($file in $files) {
                $Assemblies.Add($file.FullName)
            }
        }
    }
    else{
        Write-Warning "Unknown PowerShell version"
    }
    #Load powershell lib
    try {
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
        #Import MSAL Device Code helper
        if (-not ([System.Management.Automation.PSTypeName]'DeviceCodeHelper').Type){
            $cs_path = ("{0}/helpers/devicecode.cs" -f $PSScriptRoot)
            $cs_helper = Get-ChildItem -Path $cs_path | Where-Object {$_.Extension -in ".cs"} | Select-Object FullName -ErrorAction SilentlyContinue
            if($null -ne $cs_helper){
                $params = @{
                    LiteralPath = $cs_helper.FullName;
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
        else{
            Write-Verbose "The library [DeviceCodeHelper] is already loaded"
        }
        Write-Verbose -Message "MSAL library installed successfully"
        return $installed
    }
    catch { throw }
}

$isInstalled = Import-MonkeyMSALLib

$localizedFnc = ("{0}/private/Get-LocalizedData.ps1" -f $PSScriptRoot)
$fnc = Get-ChildItem -Path $localizedFnc -File
if($fnc -and $null -ne $isInstalled){
    #Dot source script file
    . $fnc.FullName
    #Load messages
    $script:messages = Get-LocalizedData -DefaultUICulture 'en-US'
    #Load ADAL library
    $adalInstalled = $true;#Load-MonkeyADAL
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
        Write-Warning "Unable to load MonkeyMSAL module"
    }
}
else{
    Write-Warning "Unable to load MonkeyMSAL module"
}