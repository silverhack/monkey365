Set-StrictMode -Version Latest

Describe 'ConvertTo-MonkeyObject' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        $manifestPath = Join-Path $script:repoRoot 'src\monkey365\monkey365.psd1'
        Remove-Module monkey365 -Force -ErrorAction Ignore
        Import-Module $manifestPath -Force -ErrorAction Stop
    }

    It 'converts dictionary entries to a synchronized hashtable' {
        InModuleScope monkey365 {
            $result = ConvertTo-MonkeyObject -Objects ([ordered]@{
                alpha = 1
                beta = 2
            })
            $result | Should -BeOfType [hashtable]
            $result.IsSynchronized | Should -BeTrue
            $result.alpha | Should -Be 1
            $result.beta | Should -Be 2
        }
    }

    AfterAll {
        Remove-Module monkey365 -Force -ErrorAction Ignore
    }
}
