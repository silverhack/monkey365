# filepath: c:\monkey365_dev\newhtml\monkeyhtml\private\ApexCharts\Get-StackedBarChartOption.Tests.ps1
Set-StrictMode -Version Latest
Import-Module Pester

Describe "Get-StackedBarChartOption Tests" {
    BeforeAll {
        # Import the module containing the function
        $modulePath = (Get-Item $PSScriptRoot).Parent.FullName
        Import-Module $modulePath -Force
        # Mock data for testing
        $global:MockData = @(
            @{ name = "Series 1"; data = @(10, 20, 30) },
            @{ name = "Series 2"; data = @(15, 25, 35) }
        )
        $global:MockLabels = @("Label 1", "Label 2", "Label 3")
    }

    It "Generates valid JavaScript for a basic stacked bar chart" {
        InModuleScope monkeyhtml {
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels
            $result | Should -Match "var chart = new ApexCharts"
            $result | Should -Match "chart.render"
        }
    }

    It "Correctly sets x-axis categories from Labels parameter" {
        InModuleScope monkeyhtml {
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels
            $result | Should -Match "var labels = \[""Label 1"",""Label 2"",""Label 3""\]"
        }
    }

    It "Sets horizontal orientation when Horizontal switch is used" {
        InModuleScope monkeyhtml {
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels -Horizontal
            $result | Should -Match '"horizontal":  true'
        }
    }

    It "Assigns a custom chart ID when Id parameter is provided" {
        InModuleScope monkeyhtml {
            $customId = "customChartId"
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels -Id $customId
            $result | Should -Match "document.querySelector\(""#customChartId""\)"
        }
    }

    It "Generates a unique chart ID when Id parameter is not provided" {
        InModuleScope monkeyhtml {
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels
            $result | Should -Match "document.querySelector\(""#monkeyChart"
        }
    }

    It "Handles empty Labels gracefully" {
        InModuleScope monkeyhtml {
            $result = {Get-StackedBarChartOption -Data $MockData -Labels @()} | Should -Throw
        }
    }

    It "Handles empty Data gracefully" {
        InModuleScope monkeyhtml {
            $result = {Get-StackedBarChartOption -Data @() -Labels $MockLabels} | Should -Throw
        }
    }

    It "Handles missing optional parameters correctly" {
        InModuleScope monkeyhtml {
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels
            $result | Should -Not -BeNullOrEmpty
        }
    }
}