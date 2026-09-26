Set-StrictMode -Version Latest

Describe 'Conditional Access Graph request behavior' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
        $sourcePath = Join-Path $repoRoot 'src/monkey365/core/api/entraid/msgraph/helpers/policies/Get-MonkeyMSGraphConditionalAccessPolicy.ps1'
        $source = Get-Content -LiteralPath $sourcePath -Raw
    }

    It 'preserves the Detailed compatibility parameter' {
        $source | Should -Match '\[Switch\]\$detailed'
    }

    It 'preserves collection and direct policy lookup endpoints' {
        $source | Should -Match '\$objectType\s*=\s*''identity/conditionalAccess/policies'''
        $source | Should -Match 'identity/conditionalAccess/policies/\{0\}''\s+-f\s+\$id'
    }

    It 'does not fan out collection results into per-policy requests or sleeps' {
        $source | Should -Not -Match 'foreach\s*\(\s*\$cap\s+in\s+\$caps_\s*\)'
        $source | Should -Not -Match 'identity/conditionalAccess/policies/\{0\}''\s+-f\s+\$cap\.id'
        $source | Should -Not -Match 'Start-Sleep\s+-Milliseconds\s+1000'
    }
}
