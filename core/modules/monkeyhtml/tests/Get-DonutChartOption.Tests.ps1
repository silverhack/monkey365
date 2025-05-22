# Filepath: private/ApexCharts/Get-DonutChartOption.Tests.ps1
Set-StrictMode -Version Latest
Import-Module Pester

Describe "Get-DonutChartOption Tests" {
    BeforeAll {
        # Import the module containing the function
        $module = (Get-Item $PSScriptRoot).Parent
        Import-Module $module.FullName -Force
    }

    It "Generates default donut chart options" {
        InModuleScope monkeyhtml {
            $result = Get-DonutChartOption
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "var chart = new ApexCharts"
        }
    }

    It "Processes Labels parameter correctly" {
        InModuleScope monkeyhtml {
            $labels = @("Label1", "Label2", "Label3")
            $result = Get-DonutChartOption -Labels $labels
            $result | Should -Match "var labels = \[""Label1"",""Label2"",""Label3""\];"
            $result | Should -Match '"labels"'
        }
    }

    It "Processes Colors parameter correctly" {
        InModuleScope monkeyhtml {
            $colors = @("#FF0000", "#00FF00", "#0000FF")
            $result = Get-DonutChartOption -Colors $colors
            $result | Should -Match "var colors = \[""#FF0000"",""#00FF00"",""#0000FF""\];"
            $result | Should -Match '"colors"'
        }
    }

    It "Processes Data parameter correctly" {
        InModuleScope monkeyhtml {
            $data = @(10, 20, 30)
            $result = Get-DonutChartOption -Data $data
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should -Match '"series":\[10,20,30\]'
        }
    }

    It "Uses provided Id parameter" {
        InModuleScope monkeyhtml {
            $id = "customChartId"
            $result = Get-DonutChartOption -Id $id
            $result | Should -Match "document.querySelector\(""#customChartId""\)"
        }
    }

    It "Generates default Id when Id parameter is not provided" {
        InModuleScope monkeyhtml {
            $result = Get-DonutChartOption
            $result | Should -Match "document.querySelector\(""#monkeyChart"
        }
    }

    It "Generates valid JavaScript output" {
        InModuleScope monkeyhtml {
            $result = Get-DonutChartOption -Data @(10, 20, 30) -Labels @("A", "B", "C") -Colors @("#123456", "#654321")
            $result | Should -Match "var chart = new ApexCharts"
            $result | Should -Match "chart.render\(\);"
        }
    }
}