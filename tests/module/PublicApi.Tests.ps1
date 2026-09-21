Set-StrictMode -Version Latest

Describe 'Monkey365 public API contract' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $manifestPath = Join-Path $script:repoRoot 'src\monkey365\monkey365.psd1'
        $script:expectedCommands = @(
            'Get-MonkeyJobError'
            'Invoke-Monkey365'
            'Register-Monkey365Application'
        )
        Remove-Module monkey365 -Force -ErrorAction Ignore
        Import-Module $manifestPath -Force -ErrorAction Stop
    }

    It 'exports only the supported public functions' {
        $actualCommands = @(Get-Command -Module monkey365 -CommandType Function |
            Select-Object -ExpandProperty Name | Sort-Object)
        Compare-Object $script:expectedCommands $actualCommands | Should -BeNullOrEmpty
    }

    It 'exposes Invoke-Monkey365 as an advanced function' {
        $command = Get-Command Invoke-Monkey365 -Module monkey365
        $command.CmdletBinding | Should -BeTrue
        $command.Parameters.Keys | Should -Contain 'Instance'
        $command.Parameters.Keys | Should -Contain 'ListCollector'
    }

    AfterAll {
        Remove-Module monkey365 -Force -ErrorAction Ignore
    }
}
