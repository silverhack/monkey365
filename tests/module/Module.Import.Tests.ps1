Set-StrictMode -Version Latest

Describe 'Monkey365 module import contract' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $script:manifestPath = Join-Path $script:repoRoot 'src\monkey365\monkey365.psd1'
        Remove-Module monkey365 -Force -ErrorAction Ignore
    }

    It 'imports successfully from its manifest' {
        { Import-Module $script:manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
        Get-Module monkey365 | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        Remove-Module monkey365 -Force -ErrorAction Ignore
    }
}
