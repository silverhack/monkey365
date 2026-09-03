Set-StrictMode -Version Latest

Describe "New-FindingByServiceChart Tests" {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
        [xml]$script:mockTemplate = "<html></html>"
        Mock Get-StackedBarChartOption { return "Mocked Chart Options" } -ModuleName monkeyhtml
        Mock New-HtmlTag { return "Mocked Html Tag" } -ModuleName monkeyhtml
        Mock New-HtmlContainerCard { return "Mocked Html Card" } -ModuleName monkeyhtml
    }

    It "Generates a chart with valid input" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $inputObject = @(
                [PSCustomObject]@{ Provider = "entraid"; level = "info" },
                [PSCustomObject]@{ Provider = "entraid"; level = "low" },
                [PSCustomObject]@{ Provider = "other"; level = "medium"; serviceType = "ServiceA" }
            )
            $result = New-FindingByServiceChart -InputObject $inputObject -Template $MockTemplate
            $result | Should-Be "Mocked Html Card"
            Should-Invoke -CommandName Get-StackedBarChartOption -Times 1 -Exactly
            Should-Invoke -CommandName New-HtmlTag -Times 1
        }
    }

    It "Handles HorizontalStackedBar switch correctly" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $inputObject = @(
                [PSCustomObject]@{ Provider = "entraid"; level = "info" }
            )
            $result = New-FindingByServiceChart -InputObject $inputObject -HorizontalStackedBar -Template $MockTemplate
            $result | Should-Be "Mocked Html Card"
            Should-Invoke -CommandName Get-StackedBarChartOption -Times 1 -Exactly -Scope It -ParameterFilter { $Horizontal -eq $true }
        }
    }

    It "warns and does not build a chart when no findings are present" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            Mock Write-Warning { }
            $inputObject = @()
            $result = New-FindingByServiceChart -InputObject $inputObject -Template $MockTemplate

            $result | Should-BeNull
            Should-Invoke -CommandName Get-StackedBarChartOption -Times 0 -Exactly
            Should-Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
                $Message -match 'Unable to create findings chart'
            }
        }
    }

    It "Handles invalid input gracefully" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $inputObject = $null
            { New-FindingByServiceChart -InputObject $inputObject -Template $MockTemplate } | Should-Throw
        }
    }
}
