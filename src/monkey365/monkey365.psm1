Set-StrictMode -Version Latest

$script:ScriptPath = $PSScriptRoot

# Import localized data
$LocalizedDataParams = @{
    BindingVariable = 'message';
    FileName = 'localized.psd1';
    BaseDirectory = (Join-Path $PSScriptRoot 'core/utils');
}

#Import localized data
Import-LocalizedData @LocalizedDataParams;

function Get-MonkeySourceFile {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath
    )

    $path = Join-Path $PSScriptRoot $RelativePath

    If ([System.IO.File]::Exists($path) -and ([System.IO.Path]::GetExtension($path) -eq '.ps1')) {
        return $path
    }

    throw "Source file not found: $RelativePath"
}

Function Get-MonkeySourceFiles {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath
    )

    $path = Join-Path $PSScriptRoot $RelativePath

    If (-not [System.IO.Directory]::Exists($path)) {
        return
    }

    [System.IO.Directory]::EnumerateFiles(
        $path,
        '*',
        [System.IO.SearchOption]::AllDirectories
    ) | Sort-Object
}

# Import core functions
$sourceFolders = @(
    'core/api/auth'
    'core/tenant'
    'core/collector'
    'core/utils'
    'core/subscription'
    'core/init'
    'core/import'
    'core/output'
    'core/tasks'
    'core/watcher'
)

$sourceFolders.ForEach({
    ForEach ($file in Get-MonkeySourceFiles -RelativePath $_) {
        If ([System.IO.Path]::GetExtension($file) -ne '.ps1') {
            continue
        }
        . $file
    }
})

$script:azure_plugins = @(Get-MonkeySupportedService -Azure)
$script:m365_plugins = @(Get-MonkeySupportedService -Microsoft365)

Function Get-MonkeyAzurePlugins {
    If (-not $script:azure_plugins) {
        $script:azure_plugins = Get-MonkeySupportedService -Azure
    }
    return $script:azure_plugins
}

Function Get-MonkeyM365Plugins {
    If (-not $script:m365_plugins) {
        $script:m365_plugins = Get-MonkeySupportedService -Microsoft365
    }

    return $script:m365_plugins
}

# Import core functions
$sourceFiles = @(
    'core/api/azure/resourcemanagement/api/Get-MonkeyRMObject.ps1'
    'core/api/azure/resourcemanagement/helpers/tenant/Get-MonkeyAzTenant.ps1'
    'core/api/azure/resourcemanagement/helpers/subscription/Get-MonkeyAzSubscription.ps1'
    'core/api/azure/resourcemanagement/helpers/subscription/Get-MonkeyAzClassicAdministrator.ps1'
    'core/api/azure/resourcemanagement/helpers/rbac/Get-MonkeyAzIAMPermission.ps1'
    'core/api/azure/resourcemanagement/helpers/rbac/Get-MonkeyAzRoleAssignmentForObject.ps1'
    'core/api/azure/resourcemanagement/helpers/rbac/Get-MonkeyAzRoleDefinitionObject.ps1'
    'core/api/azure/resourcemanagement/helpers/general/Get-MonkeyAzResourceGroup.ps1'
    'core/api/azure/resourcemanagement/helpers/general/Get-MonkeyAzResource.ps1'
    'core/api/azure/resourcemanagement/helpers/general/Get-MonkeyAzProviderOperation.ps1'
    'core/api/entraid/msgraph/api/Get-MonkeyMSGraphObject.ps1'
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphOrganization.ps1'
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphSuscribedSku.ps1'
    'core/api/entraid/msgraph/helpers/domain/Get-MonkeyMSGraphDomain.ps1'
    'core/api/entraid/msgraph/helpers/general/Test-CanRequestGroup.ps1'
    'core/api/entraid/msgraph/helpers/general/Test-CanRequestUser.ps1'
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphDirectoryObjectById.ps1'
    'core/api/entraid/msgraph/helpers/general/Get-MonkeyMSGraphProfilePhoto.ps1'
    'core/api/entraid/msgraph/helpers/users/Get-MonkeyMSGraphUser.ps1'
    'core/api/entraid/msgraph/helpers/groups/Get-MonkeyMSGraphGroup.ps1'
    'core/api/entraid/msgraph/helpers/groups/Get-MonkeyMSGraphGroupTransitiveMember.ps1'
    'core/api/entraid/msgraph/helpers/serviceprincipals/Get-MonkeyMSGraphAADServicePrincipal.ps1'
    'core/api/entraid/msgraph/helpers/directoryrole/Get-MonkeyMSGraphEntraDirectoryRole.ps1'
    'core/api/entraid/msgraph/helpers/directoryrole/Get-MonkeyMSGraphEntraRoleAssignment.ps1'
    'core/api/entraid/msgraph/helpers/directoryrole/Get-MonkeyMSGraphObjectDirectoryRole.ps1'
    'core/api/m365/exchangeonline/helpers/Get-PSExoModuleFile.ps1'
    'core/api/m365/exchangeonline/api/ConvertTo-ExoRestCommand.ps1'
    'core/api/m365/exchangeonline/api/Get-PSExoAdminApiObject.ps1'
    'core/api/m365/microsoftteams/api/Get-MonkeyTeamsObject.ps1'
    'core/api/m365/microsoftteams/helpers/service/Get-MonkeyTeamsServiceDiscovery.ps1'
    'core/api/m365/microsoftteams/helpers/service/Test-TeamsConnection.ps1'
    'core/api/m365/sharepointonline/csom/api/Invoke-MonkeyCSOMRequest.ps1'
    'core/api/m365/sharepointonline/csom/api/Invoke-MonkeyCSOMDefaultRequest.ps1'
    'core/api/m365/sharepointonline/csom/helpers/site/Get-MonkeyCSOMSite.ps1'
    'core/api/m365/sharepointonline/csom/helpers/site/Get-MonkeyCSOMSiteProperty.ps1'
    'core/api/m365/sharepointonline/utils/Test-IsUserSharepointAdministrator.ps1'
    'core/api/m365/sharepointonline/utils/Test-SiteConnection.ps1'
    'core/scan/Invoke-AzureScanner.ps1'
    'core/scan/Invoke-EntraIDScanner.ps1'
    'core/scan/Invoke-M365Scanner.ps1'
) | Select-Object -Unique

$sourceFiles.ForEach({. (Get-MonkeySourceFile -RelativePath $_)})
# Import Monkey365
. (Get-MonkeySourceFile -RelativePath 'Invoke-Monkey365.ps1')
