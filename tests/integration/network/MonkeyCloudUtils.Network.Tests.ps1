Set-StrictMode -Version Latest

Describe 'MonkeyCloudUtils network integration' -Tag 'Network' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        Import-Module (Join-Path $script:repoRoot 'src\monkey365\core\modules\monkeymsal') -Force -ErrorAction Stop
        Import-Module (Join-Path $script:repoRoot 'src\monkey365\core\modules\monkeycloudutils') -Force -ErrorAction Stop
    }

    It 'retrieves public tenant information' {
        InModuleScope monkeycloudutils {
            (Get-PublicTenantInformation -Domain 'fbi.gov').TenantRegionScope | Should -Be 'USGov'
        }
    }

    AfterAll {
        Remove-Module monkeycloudutils, monkeymsal -Force -ErrorAction Ignore
    }
}
