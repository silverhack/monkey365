Set-StrictMode -Version Latest

Describe 'MonkeyHTML semantic mappings' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'maps severity <Value> to color <Expected>' -TestCases @(
        @{ Value = 'Info'; Expected = 'monkey-info' }
        @{ Value = 'low'; Expected = 'monkey-low' }
        @{ Value = 'MEDIUM'; Expected = 'monkey-warning' }
        @{ Value = 'high'; Expected = 'monkey-danger' }
        @{ Value = 'critical'; Expected = 'monkey-critical' }
        @{ Value = 'unknown'; Expected = 'monkey-unknown' }
        @{ Value = 'unexpected'; Expected = 'monkey-unknown' }
    ) {
        InModuleScope monkeyhtml -Parameters @{ Severity = $Value; Result = $Expected } {
            Get-ColorFromLevel -InputObject $Severity | Should-Be $Result
        }
    }

    It 'maps severity <Value> to icon <Expected>' -TestCases @(
        @{ Value = 'medium'; Expected = 'finding-badge-warning' }
        @{ Value = 'info'; Expected = 'finding-badge-info' }
        @{ Value = 'low'; Expected = 'finding-badge-low' }
        @{ Value = 'good'; Expected = 'finding-badge-good' }
        @{ Value = 'high'; Expected = 'finding-badge-danger' }
        @{ Value = 'critical'; Expected = 'finding-badge-critical' }
        @{ Value = 'manual'; Expected = 'finding-badge-manual' }
        @{ Value = 'unexpected'; Expected = 'finding-badge-unknown' }
    ) {
        InModuleScope monkeyhtml -Parameters @{ Severity = $Value; Suffix = $Expected } {
            Get-IconFromLevel -InputObject $Severity | Should-MatchString ([regex]::Escape($Suffix) + '$')
        }
    }

    It 'maps severity <Value> to badge <Expected>' -TestCases @(
        @{ Value = 'medium'; Expected = 'badge-warning' }
        @{ Value = 'info'; Expected = 'badge-info' }
        @{ Value = 'low'; Expected = 'badge-low' }
        @{ Value = 'good'; Expected = 'badge-success' }
        @{ Value = 'high'; Expected = 'badge-danger' }
        @{ Value = 'critical'; Expected = 'badge-critical' }
        @{ Value = 'unexpected'; Expected = 'badge-unknown' }
    ) {
        InModuleScope monkeyhtml -Parameters @{ Severity = $Value; Result = $Expected } {
            Get-BadgeFromLevel -InputObject $Severity | Should-Be $Result
        }
    }

    It 'maps status <Value> to badge <Expected>' -TestCases @(
        @{ Value = 'pass'; Expected = 'badge-success' }
        @{ Value = 'FAIL'; Expected = 'badge-danger' }
        @{ Value = 'manual'; Expected = 'badge-manual' }
        @{ Value = 'unknown'; Expected = 'badge-unknown' }
    ) {
        InModuleScope monkeyhtml -Parameters @{ Status = $Value; Result = $Expected } {
            Get-BadgeFromStatusCode -InputObject $Status | Should-Be $Result
        }
    }
}
