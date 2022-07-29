#Set-StrictMode -Off #-Version Latest
Set-StrictMode -Version Latest

$LocalizedDataParams = @{
    BindingVariable = 'message';
    FileName = 'localized.psd1';
    BaseDirectory = "{0}/{1}" -f $PSScriptRoot, "core/utils";
}
#Import localized data
Import-LocalizedData @LocalizedDataParams;

#Load all modules
$Modules = @{
    utils = '/core/utils/'
    azure_api = '/core/api/azure/'
    init = '/core/init/'
    runspaces = '/core/tasks/'
    auth = '/core/api/auth/'
    analysis = '/core/analysis/'
    office = '/core/office/'
    html = '/core/html/'
    o365_api = '/core/api/o365/'
    watcher = '/core/watcher/'
    output = '/core/output/'
    import = '/core/import/'
}
#Import modules
foreach($module in $Modules.GetEnumerator()){
    $metadata = [System.IO.File]::GetAttributes(("{0}{1}" -f $PSScriptRoot, $module.value))
    if($metadata -eq "Directory"){
        $all_files = Get-ChildItem -Recurse -Path ("{0}{1}" -f $PSScriptRoot, $module.value) -File -Include "*.ps1" -ErrorAction SilentlyContinue
        if($null -ne $all_files){
            foreach ($mod in $all_files){
                Write-Verbose ("Loading {0} module" -f $mod.FullName)
                . $mod.FullName
            }
        }
    }
    else{
        Write-Verbose ("Loading {0} module" -f $module.Name)
        $tmp_module = ("{0}{1}" -f $PSScriptRoot, $module.value)
        . $tmp_module.ToString()
    }
}

#$ScriptPath = $PSScriptRoot
New-Variable -Name ScriptPath -Value $PSScriptRoot -Scope Script -Force

#Update PsObject
Update-PsObject
#Import ADAL/MSAL MODULES
Import-O365Lib

$monkey = ("{0}\Invoke-Monkey365.ps1" -f $PSScriptRoot)
. $monkey