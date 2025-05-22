# filepath: private/ApexCharts/New-FindingByServiceChart.Tests.ps1
Set-StrictMode -Version Latest
Import-Module Pester

Describe "New-FindingByServiceChart Tests" {
    BeforeAll {
        $module = (Get-Item $PSScriptRoot).Parent
        Import-Module $module.FullName -Force
        # Mock template object
        [xml]$global:MockTemplate = "<html></html>"
        Mock Get-StackedBarChartOption { return "Mocked Chart Options" } -ModuleName monkeyhtml
        Mock New-HtmlTag { return "Mocked Html Tag" } -ModuleName monkeyhtml
        Mock New-HtmlContainerCard { return "Mocked Html Card" } -ModuleName monkeyhtml
    }

    It "Generates a chart with valid input" {
        InModuleScope monkeyhtml {
            $inputObject = @(
                [PSCustomObject]@{ Provider = "entraid"; level = "info" },
                [PSCustomObject]@{ Provider = "entraid"; level = "low" },
                [PSCustomObject]@{ Provider = "other"; level = "medium"; serviceType = "ServiceA" }
            )
            $result = New-FindingByServiceChart -InputObject $inputObject -Template $MockTemplate
            $result | Should -be "Mocked Html Card"
            Assert-MockCalled -CommandName Get-StackedBarChartOption -Exactly 1
            Assert-MockCalled -CommandName New-HtmlTag -Times 1
        }
    }

    It "Handles HorizontalStackedBar switch correctly" {
        InModuleScope monkeyhtml {
            $inputObject = @(
                [PSCustomObject]@{ Provider = "entraid"; level = "info" }
            )
            $result = New-FindingByServiceChart -InputObject $inputObject -HorizontalStackedBar -Template $MockTemplate
            $result | Should -be "Mocked Html Card"
            Assert-MockCalled -CommandName Get-StackedBarChartOption -Exactly 1 -Scope It -ParameterFilter { $Horizontal -eq $true }
        }
    }

    It "Returns warning when no findings are present" {
        InModuleScope monkeyhtml {
            $inputObject = @()
            $result = { New-FindingByServiceChart -InputObject $inputObject -Template $MockTemplate } | Should -Not -Throw
            Assert-MockCalled -CommandName Get-StackedBarChartOption -Times 0
        }
    }

    It "Handles invalid input gracefully" {
        InModuleScope monkeyhtml {
            $inputObject = $null
            { New-FindingByServiceChart -InputObject $inputObject -Template $MockTemplate } | Should -Throw
        }
    }
}