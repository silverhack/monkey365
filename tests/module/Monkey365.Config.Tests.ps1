Set-StrictMode -Version Latest

Describe 'Monkey365 configuration contract' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $script:moduleRoot = Join-Path $script:repoRoot 'src\monkey365'
        $script:configPath = Join-Path $script:moduleRoot 'config\monkey365.config'
        $script:config = Get-Content -LiteralPath $script:configPath -Raw |
            ConvertFrom-Json -ErrorAction Stop
    }

    It 'is valid JSON' {
        $script:config | Should -Not -BeNullOrEmpty
    }

    It 'contains the required top-level section <_>' -ForEach @(
        'httpSettings'
        'performance'
        'htmlSettings'
        'ruleSettings'
        'logging'
        'o365'
        'entraId'
        'resourceManager'
    ) {
        $script:config.PSObject.Properties.Name | Should -Contain $_
    }

    It 'uses valid positive performance settings' {
        $script:config.performance.BatchSleep | Should -BeGreaterThan 0
        $script:config.performance.BatchSize | Should -BeGreaterThan 0
        $script:config.performance.nestedRunspaces.MaxQueue | Should -BeGreaterThan 0
    }

    It 'references an existing rules directory' {
        Join-Path $script:moduleRoot $script:config.ruleSettings.rules | Should -Exist
    }

    It 'references an existing default ruleset <_>' -ForEach @(
        'azureDefaultRuleset'
        'm365DefaultRuleset'
    ) {
        Join-Path $script:moduleRoot $script:config.ruleSettings.$_ | Should -Exist
    }

    It 'contains unique, non-empty Microsoft Graph scopes' {
        $scopes = @($script:config.entraId.mgGraph.scopes)
        $scopes.Count | Should -BeGreaterThan 0
        @($scopes | Where-Object { [string]::IsNullOrWhiteSpace($_) }) | Should -BeNullOrEmpty
        @($scopes | Group-Object | Where-Object Count -gt 1) | Should -BeNullOrEmpty
    }
}
