Set-StrictMode -Version Latest

Describe "Get-DonutChartOption Tests" {
    BeforeAll {
        # Import the module containing the function
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It "Generates default donut chart options" {
        InModuleScope monkeyhtml {
            $result = Get-DonutChartOption
            $result | Should-NotBeEmptyString
            $result | Should-MatchString "var chart = new ApexCharts"
        }
    }

    It "Processes Labels parameter correctly" {
        InModuleScope monkeyhtml {
            $labels = @("Label1", "Label2", "Label3")
            $result = Get-DonutChartOption -Labels $labels
            $result | Should-MatchString "var labels = \[""Label1"",""Label2"",""Label3""\];"
            $result | Should-MatchString '"labels"'
        }
    }

    It "Processes Colors parameter correctly" {
        InModuleScope monkeyhtml {
            $colors = @("#FF0000", "#00FF00", "#0000FF")
            $result = Get-DonutChartOption -Colors $colors
            $result | Should-MatchString "var colors = \[""#FF0000"",""#00FF00"",""#0000FF""\];"
            $result | Should-MatchString '"colors"'
        }
    }

    It "Processes Data parameter correctly" {
        InModuleScope monkeyhtml {
            $data = @(10, 20, 30)
            $result = Get-DonutChartOption -Data $data
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should-MatchString '"series":\[10,20,30\]'
        }
    }

    It "Uses provided Id parameter" {
        InModuleScope monkeyhtml {
            $id = "customChartId"
            $result = Get-DonutChartOption -Id $id
            $result | Should-MatchString "document.querySelector\(""#customChartId""\)"
        }
    }

    It "Generates default Id when Id parameter is not provided" {
        InModuleScope monkeyhtml {
            $result = Get-DonutChartOption
            $result | Should-MatchString "document.querySelector\(""#monkeyChart"
        }
    }

    It "Generates valid JavaScript output" {
        InModuleScope monkeyhtml {
            $result = Get-DonutChartOption -Data @(10, 20, 30) -Labels @("A", "B", "C") -Colors @("#123456", "#654321")
            $result | Should-MatchString "var chart = new ApexCharts"
            $result | Should-MatchString "chart.render\(\);"
        }
    }
}
