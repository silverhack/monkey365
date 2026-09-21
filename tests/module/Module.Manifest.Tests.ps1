Set-StrictMode -Version Latest

Describe 'Monkey365 module manifest contract' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $script:moduleRoot = Join-Path $script:repoRoot 'src\monkey365'
        $script:manifestPath = Join-Path $script:moduleRoot 'monkey365.psd1'
        $script:manifestData = Import-PowerShellDataFile -Path $script:manifestPath
    }

    It 'passes Test-ModuleManifest' {
        { Test-ModuleManifest -Path $script:manifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'references an existing root module' {
        Join-Path $script:moduleRoot $script:manifestData.RootModule | Should -Exist
    }

    It 'has valid release metadata' {
        $script:manifestData.ModuleVersion | Should -Match '^\d+\.\d+(\.\d+)?$'
        $script:manifestData.GUID | Should -Not -BeNullOrEmpty
        $script:manifestData.Author | Should -Not -BeNullOrEmpty
        $script:manifestData.Description | Should -Not -BeNullOrEmpty
    }
}
