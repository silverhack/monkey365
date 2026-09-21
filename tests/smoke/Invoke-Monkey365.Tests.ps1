Set-StrictMode -Version Latest

Describe 'Invoke-Monkey365 credential-free smoke test' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $manifestPath = Join-Path $script:repoRoot 'src\monkey365\monkey365.psd1'
        Remove-Module monkey365 -Force -ErrorAction Ignore
        Import-Module $manifestPath -Force -ErrorAction Stop
    }

    It 'lists Azure collectors without authentication or network access' {
        { Invoke-Monkey365 -Instance Azure -ListCollector | Out-Null } | Should -Not -Throw
    }

    AfterAll {
        Remove-Module monkey365 -Force -ErrorAction Ignore
    }
}
