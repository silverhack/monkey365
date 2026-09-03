Set-StrictMode -Version Latest

Describe "Get-StackedBarChartOption Tests" {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
        $script:mockData = @(
            @{ name = "Series 1"; data = @(10, 20, 30) },
            @{ name = "Series 2"; data = @(15, 25, 35) }
        )
        $script:mockLabels = @("Label 1", "Label 2", "Label 3")
    }

    It "Generates valid JavaScript for a basic stacked bar chart" {
        InModuleScope monkeyhtml -Parameters @{
            MockData = $script:mockData
            MockLabels = $script:mockLabels
        } {
            param($MockData, $MockLabels)
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels
            $result | Should-MatchString "var chart = new ApexCharts"
            $result | Should-MatchString "chart.render"
        }
    }

    It "Correctly sets x-axis categories from Labels parameter" {
        InModuleScope monkeyhtml -Parameters @{
            MockData = $script:mockData
            MockLabels = $script:mockLabels
        } {
            param($MockData, $MockLabels)
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels
            $result | Should-MatchString "var labels = \[""Label 1"",""Label 2"",""Label 3""\]"
        }
    }

    It "Sets horizontal orientation when Horizontal switch is used" {
        InModuleScope monkeyhtml -Parameters @{
            MockData = $script:mockData
            MockLabels = $script:mockLabels
        } {
            param($MockData, $MockLabels)
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels -Horizontal
            $result | Should-MatchString '"horizontal":\s*true'
        }
    }

    It "Assigns a custom chart ID when Id parameter is provided" {
        InModuleScope monkeyhtml -Parameters @{
            MockData = $script:mockData
            MockLabels = $script:mockLabels
        } {
            param($MockData, $MockLabels)
            $customId = "customChartId"
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels -Id $customId
            $result | Should-MatchString "document.querySelector\(""#customChartId""\)"
        }
    }

    It "Generates a unique chart ID when Id parameter is not provided" {
        InModuleScope monkeyhtml -Parameters @{
            MockData = $script:mockData
            MockLabels = $script:mockLabels
        } {
            param($MockData, $MockLabels)
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels
            $result | Should-MatchString "document.querySelector\(""#monkeyChart"
        }
    }

    It "Handles empty Labels gracefully" {
        InModuleScope monkeyhtml -Parameters @{
            MockData = $script:mockData
            MockLabels = $script:mockLabels
        } {
            param($MockData, $MockLabels)
            { Get-StackedBarChartOption -Data $MockData -Labels @() } | Should-Throw
        }
    }

    It "Handles empty Data gracefully" {
        InModuleScope monkeyhtml -Parameters @{
            MockData = $script:mockData
            MockLabels = $script:mockLabels
        } {
            param($MockData, $MockLabels)
            { Get-StackedBarChartOption -Data @() -Labels $MockLabels } | Should-Throw
        }
    }

    It "Handles missing optional parameters correctly" {
        InModuleScope monkeyhtml -Parameters @{
            MockData = $script:mockData
            MockLabels = $script:mockLabels
        } {
            param($MockData, $MockLabels)
            $result = Get-StackedBarChartOption -Data $MockData -Labels $MockLabels
            $result | Should-NotBeEmptyString
        }
    }
}
