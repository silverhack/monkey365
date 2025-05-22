# filepath: private/ApexCharts/Get-PolarAreaChartOption.Tests.ps1
Set-StrictMode -Version Latest
Import-Module Pester

Describe "Get-PolarAreaChartOption Tests" {
    BeforeAll {
        # Import the module containing the function
        $modulePath = (Get-Item $PSScriptRoot).Parent.FullName
        Import-Module $modulePath -Force
    }

    It "Returns valid chart options with no parameters" {
        InModuleScope monkeyhtml {
            $result = Get-PolarAreaChartOption
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "var options ="
            $result | Should -Match "polarArea"
        }
    }

    It "Handles Data parameter correctly" {
        InModuleScope monkeyhtml {
            $data = @(10, 20, 30)
            $result = Get-PolarAreaChartOption -Data $data
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should -Match '"series":\[10,20,30\]'
        }
    }

    It "Handles Labels parameter correctly" {
        InModuleScope monkeyhtml {
            $labels = @("Label1", "Label2", "Label3")
            $result = Get-PolarAreaChartOption -Labels $labels
            $result | Should -Match 'var labels = \["Label1","Label2","Label3"\];'
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should -Match '"labels":labels'
        }
    }

    It "Handles Colors parameter correctly" {
        InModuleScope monkeyhtml {
            $colors = @("#FF0000", "#00FF00", "#0000FF")
            $result = Get-PolarAreaChartOption -Colors $colors
            $result | Should -Match 'var colors = \["#FF0000","#00FF00","#0000FF"\];'
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should -Match '"colors":colors'
        }
    }

    It "Generates a unique Id when Id parameter is not provided" {
        InModuleScope monkeyhtml {
            $result = Get-PolarAreaChartOption
            $result | Should -Match 'var chart = new ApexCharts\(document.querySelector\("#monkeyChart[a-zA-Z0-9]+"\), options\);'
        }
    }

    It "Uses provided Id when Id parameter is specified" {
        InModuleScope monkeyhtml {
            $id = "customChartId"
            $result = Get-PolarAreaChartOption -Id $id
            $result | Should -Match  "document.querySelector\(""#customChartId""\)"
        }
    }

    It "Handles all parameters together correctly" {
        InModuleScope monkeyhtml {
            $data = @(10, 20, 30)
            $labels = @("Label1", "Label2", "Label3")
            $colors = @("#FF0000", "#00FF00", "#0000FF")
            $id = "testChartId"
            $result = Get-PolarAreaChartOption -Data $data -Labels $labels -Colors $colors -Id $id
            $result | Should -Match 'var colors = \["#FF0000","#00FF00","#0000FF"\];'
            $result | Should -Match 'var labels = \["Label1","Label2","Label3"\];'
            $result | Should -Match "document.querySelector\(""#testChartId""\)"
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should -Match '"series":\[10,20,30\]'
        }
    }

    It "Replaces placeholders for Labels and Colors correctly" {
        InModuleScope monkeyhtml {
            $labels = @("Label1", "Label2")
            $colors = @("#FF0000", "#00FF00")
            $result = Get-PolarAreaChartOption -Labels $labels -Colors $colors
            $result | Should -Not -Match '\$\{labels\}'
            $result | Should -Not -Match '\$\{colors\}'
        }
    }

    It "Cleans up resources in the End block" {
        InModuleScope monkeyhtml {
            $result = Get-PolarAreaChartOption
            $result | Should -Not -BeNullOrEmpty
            # Ensure no exceptions are thrown during cleanup
        }
    }
}