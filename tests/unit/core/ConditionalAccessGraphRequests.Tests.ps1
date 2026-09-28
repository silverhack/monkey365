Set-StrictMode -Version Latest

Describe 'Conditional Access Graph request behavior' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
        $sourcePath = Join-Path $repoRoot 'src/monkey365/core/api/entraid/msgraph/helpers/policies/Get-MonkeyMSGraphConditionalAccessPolicy.ps1'
        $source = Get-Content -LiteralPath $sourcePath -Raw
    }

    It 'does not expose the removed Detailed parameter' {
        Should-NotMatchString -Actual $source -Expected '\[Switch\]\$detailed'
    }

    It 'preserves collection and direct policy lookup endpoints' {
        Should-MatchString -Actual $source -Expected '\$objectType\s*=\s*''identity/conditionalAccess/policies'''
        Should-MatchString -Actual $source -Expected 'identity/conditionalAccess/policies/\{0\}''\s+-f\s+\$id'
    }

    It 'does not fan out collection results into per-policy requests or sleeps' {
        Should-NotMatchString -Actual $source -Expected 'foreach\s*\(\s*\$cap\s+in\s+\$caps_\s*\)'
        Should-NotMatchString -Actual $source -Expected 'identity/conditionalAccess/policies/\{0\}''\s+-f\s+\$cap\.id'
        Should-NotMatchString -Actual $source -Expected 'Start-Sleep\s+-Milliseconds\s+1000'
    }
}
