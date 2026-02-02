#Set-StrictMode -Off #-Version Latest
Set-StrictMode -Version Latest

$LocalizedDataParams = @{
    BindingVariable = 'message';
    FileName = 'localized.psd1';
    BaseDirectory = "{0}/{1}" -f $PSScriptRoot, "core/utils";
}
#Import localized data
Import-LocalizedData @LocalizedDataParams;

$internal_modules = @(
    'core/modules/monkeylogger',
    'core/modules/monkeycloudutils',
    'core/modules/monkeyutils',
    'core/modules/monkeyhttpwebrequest',
    'core/modules/psmarkdig',
    'core/modules/monkeyhtml',
    'core/modules/monkeyjob',
    'core/modules/monkeyruleset',
    'core/modules/psocsf',
    'core/modules/monkeyoutput'
)
$internal_modules.ForEach({Import-Module ("{0}{1}{2}" -f $PSScriptRoot,[System.IO.Path]::DirectorySeparatorChar, $_.ToString()) -Force})

New-Variable -Name ScriptPath -Value $PSScriptRoot -Scope Script -Force

#Get Azure plugins
$cmds = [System.IO.Directory]::EnumerateFiles(("{0}/core/collector" -f $PSScriptRoot),"*.ps1",[System.IO.SearchOption]::AllDirectories)
$modules = @(
    ("{0}/core/modules/monkeyutils" -f $PSScriptRoot)
)
$p = @{
    ScriptBlock = {Get-MonkeySupportedService -Azure};
    ImportCommands = $cmds;
    ImportModules = $modules;
    ImportVariables = @{"ScriptPath" = $PSScriptRoot};
}
[void](Start-MonkeyJob @p)
Get-MonkeyJob | Wait-MonkeyJob
$azure_plugins = Get-MonkeyJob | Receive-MonkeyJob
#Remove Job
Get-MonkeyJob | Remove-MonkeyJob
New-Variable -Name azure_plugins -Value $azure_plugins -Scope Script -Force
#Get Microsoft 365 plugins
$p = @{
    ScriptBlock = {Get-MonkeySupportedService -Microsoft365};
    ImportModules = $modules;
    ImportCommands = $cmds;
    ImportVariables = @{"ScriptPath" = $PSScriptRoot};
}
[void](Start-MonkeyJob @p)
Get-MonkeyJob | Wait-MonkeyJob
$m365_plugins = Get-MonkeyJob | Receive-MonkeyJob
New-Variable -Name m365_plugins -Value $m365_plugins -Scope Script -Force
#Remove Job
Get-MonkeyJob | Remove-MonkeyJob

$internal_functions = @(
    'core/api/auth',
    'core/tenant',
    'core/collector',
    'core/utils',
    'core/subscription',
    'core/init',
    'core/import',
    'core/output',
    'core/tasks',
    'core/watcher'
)
$all_files = $internal_functions.ForEach({
    If([System.IO.Directory]::Exists(("{0}/{1}" -f $PSScriptRoot,$_))){
        [System.IO.Directory]::EnumerateFiles(("{0}/{1}" -f $PSScriptRoot,$_),"*.ps1",[System.IO.SearchOption]::AllDirectories)
    }
})
$all_files = $all_files.Where({$_.EndsWith('ps1')})
$all_files.ForEach({. $_})

#Internal files
$internal_files = @(
    'core/api/azure/resourcemanagement/api/Get-MonkeyRMObject.ps1',
    'core/api/azure/resourcemanagement/helpers/tenant/Get-MonkeyAzTenant.ps1',
    'core/api/azure/resourcemanagement/helpers/subscription/Get-MonkeyAzSubscription.ps1',
    'core/api/azure/resourcemanagement/helpers/subscription/Get-MonkeyAzClassicAdministrator.ps1',
    'core/api/azure/resourcemanagement/helpers/rbac/Get-MonkeyAzIAMPermission.ps1',
    'core/api/azure/resourcemanagement/helpers/rbac/Get-MonkeyAzRoleAssignmentForObject.ps1',
    'core/api/azure/resourcemanagement/helpers/rbac/Get-MonkeyAzRoleDefinitionObject.ps1',
    'core/api/azure/resourcemanagement/helpers/general/Get-MonkeyAzResourceGroup.ps1',
    'core/api/azure/resourcemanagement/helpers/general/Get-MonkeyAzResource.ps1',
    'core/api/azure/resourcemanagement/helpers/general/Get-MonkeyAzProviderOperation.ps1',
    'core/api/entraid/msgraph/api/Get-MonkeyMSGraphObject.ps1',
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphOrganization.ps1',
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphSuscribedSku.ps1',
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphSuscribedSku.ps1',
    'core/api/entraid/msgraph/helpers/domain/Get-MonkeyMSGraphDomain.ps1',
    'core/api/entraid/msgraph/helpers/general/Test-CanRequestGroup.ps1',
    'core/api/entraid/msgraph/helpers/general/Test-CanRequestUser.ps1',
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphDirectoryObjectById.ps1',
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphProfilePhoto.ps1',
    'core/api/entraid/msgraph/helpers/users/Get-MonkeyMSGraphUser.ps1',
    'core/api/entraid/msgraph/helpers/groups/Get-MonkeyMSGraphGroup.ps1',
    'core/api/entraid/msgraph/helpers/groups/Get-MonkeyMSGraphGroupTransitiveMember.ps1',
    'core/api/entraid/msgraph/helpers/serviceprincipals/Get-MonkeyMSGraphAADServicePrincipal.ps1',
    'core/api/entraid/msgraph/helpers/directoryrole/Get-MonkeyMSGraphEntraDirectoryRole.ps1',
    'core/api/entraid/msgraph/helpers/directoryrole/Get-MonkeyMSGraphEntraRoleAssignment.ps1',
    'core/api/entraid/msgraph/helpers/directoryrole/Get-MonkeyMSGraphObjectDirectoryRole.ps1',
    'core/api/m365/exchangeonline/helpers/Get-PSExoModuleFile.ps1',
    'core/api/m365/exchangeonline/api/ConvertTo-ExoRestCommand.ps1',
    'core/api/m365/exchangeonline/api/Get-PSExoAdminApiObject.ps1',
    'core/api/m365/microsoftteams/api/Get-MonkeyTeamsObject.ps1',
    'core/api/m365/microsoftteams/helpers/service/Get-MonkeyTeamsServiceDiscovery.ps1',
    'core/api/m365/microsoftteams/helpers/service/Test-TeamsConnection.ps1',
    'core/api/m365/sharepointonline/csom/api/Invoke-MonkeyCSOMRequest.ps1',
    'core/api/m365/sharepointonline/csom/api/Invoke-MonkeyCSOMDefaultRequest.ps1',
    'core/api/m365/sharepointonline/csom/helpers/site/Get-MonkeyCSOMSite.ps1',
    'core/api/m365/sharepointonline/csom/helpers/site/Get-MonkeyCSOMSiteProperty.ps1',
    'core/api/m365/sharepointonline/utils/Test-IsUserSharepointAdministrator.ps1',
    'core/api/m365/sharepointonline/utils/Test-SiteConnection.ps1',
    'core/scan/Invoke-AzureScanner.ps1',
    'core/scan/Invoke-EntraIDScanner.ps1',
    'core/scan/Invoke-M365Scanner.ps1'
)
$internal_files = $internal_files.ForEach({[System.IO.FileInfo]::new(("{0}/{1}" -f $PSScriptRoot,$_))})
$internal_files.ForEach({. $_.FullName})

$monkey = ("{0}/Invoke-Monkey365.ps1" -f $PSScriptRoot)
. $monkey
