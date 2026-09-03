Set-StrictMode -Version Latest

Describe "Get-PolarAreaChartOption Tests" {
    BeforeAll {
        # Import the module containing the function
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It "Returns valid chart options with no parameters" {
        InModuleScope monkeyhtml {
            $result = Get-PolarAreaChartOption
            $result | Should-NotBeEmptyString
            $result | Should-MatchString "var options ="
            $result | Should-MatchString "polarArea"
        }
    }

    It "Handles Data parameter correctly" {
        InModuleScope monkeyhtml {
            $data = @(10, 20, 30)
            $result = Get-PolarAreaChartOption -Data $data
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should-MatchString '"series":\[10,20,30\]'
        }
    }

    It "Handles Labels parameter correctly" {
        InModuleScope monkeyhtml {
            $labels = @("Label1", "Label2", "Label3")
            $result = Get-PolarAreaChartOption -Labels $labels
            $result | Should-MatchString 'var labels = \["Label1","Label2","Label3"\];'
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should-MatchString '"labels":labels'
        }
    }

    It "Handles Colors parameter correctly" {
        InModuleScope monkeyhtml {
            $colors = @("#FF0000", "#00FF00", "#0000FF")
            $result = Get-PolarAreaChartOption -Colors $colors
            $result | Should-MatchString 'var colors = \["#FF0000","#00FF00","#0000FF"\];'
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should-MatchString '"colors":colors'
        }
    }

    It "Generates a unique Id when Id parameter is not provided" {
        InModuleScope monkeyhtml {
            $result = Get-PolarAreaChartOption
            $result | Should-MatchString 'var chart = new ApexCharts\(document.querySelector\("#monkeyChart[a-zA-Z0-9]+"\), options\);'
        }
    }

    It "Uses provided Id when Id parameter is specified" {
        InModuleScope monkeyhtml {
            $id = "customChartId"
            $result = Get-PolarAreaChartOption -Id $id
            $result | Should-MatchString "document.querySelector\(""#customChartId""\)"
        }
    }

    It "Handles all parameters together correctly" {
        InModuleScope monkeyhtml {
            $data = @(10, 20, 30)
            $labels = @("Label1", "Label2", "Label3")
            $colors = @("#FF0000", "#00FF00", "#0000FF")
            $id = "testChartId"
            $result = Get-PolarAreaChartOption -Data $data -Labels $labels -Colors $colors -Id $id
            $result | Should-MatchString 'var colors = \["#FF0000","#00FF00","#0000FF"\];'
            $result | Should-MatchString 'var labels = \["Label1","Label2","Label3"\];'
            $result | Should-MatchString "document.querySelector\(""#testChartId""\)"
            $result = $result -replace [System.Environment]::NewLine,"" -replace " ",""
            $result | Should-MatchString '"series":\[10,20,30\]'
        }
    }

    It "Replaces placeholders for Labels and Colors correctly" {
        InModuleScope monkeyhtml {
            $labels = @("Label1", "Label2")
            $colors = @("#FF0000", "#00FF00")
            $result = Get-PolarAreaChartOption -Labels $labels -Colors $colors
            $result | Should-NotMatchString '\$\{labels\}'
            $result | Should-NotMatchString '\$\{colors\}'
        }
    }

    It "Cleans up resources in the End block" {
        InModuleScope monkeyhtml {
            $result = Get-PolarAreaChartOption
            $result | Should-NotBeEmptyString
            # Ensure no exceptions are thrown during cleanup
        }
    }
}
