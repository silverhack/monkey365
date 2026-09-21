Set-StrictMode -Version Latest

Describe "New-FindingBySeverityChart" {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop

        $script:mockInput = @(
            @{ level = "High" },
            @{ level = "Medium" },
            @{ level = "Low" },
            @{ level = "Good" },
            @{ level = "Manual" },
            @{ level = "High" }
        )

        [xml]$script:mockTemplate = "<html></html>"

        Mock Get-ColorFromLevel { return "danger" } -ModuleName monkeyhtml
        Mock Get-DonutChartOption { return "var donutOptions = {};" } -ModuleName monkeyhtml
        Mock Get-PolarAreaChartOption { return "var polarOptions = {};" } -ModuleName monkeyhtml
    }

    BeforeEach {
        Mock Get-Random { return 123 } -ModuleName monkeyhtml
    }

    It "Creates a polar area chart by default" {
        InModuleScope monkeyhtml -Parameters @{
            MockInput = $script:mockInput
            MockTemplate = $script:mockTemplate
        } {
            param($MockInput, $MockTemplate)
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

            Should-Invoke Get-PolarAreaChartOption -Times 1
            $result.GetAttribute("class") | Should-MatchString "h-100"
        }
    }
    It "Creates a donut chart when specified" {
        InModuleScope monkeyhtml -Parameters @{
            MockInput = $script:mockInput
            MockTemplate = $script:mockTemplate
        } {
            param($MockInput, $MockTemplate)
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate -Donut

            Should-Invoke Get-DonutChartOption -Times 1
            $result.GetAttribute("class") | Should-MatchString "h-100"
        }
    }

    It "Filters out 'good' and 'manual' levels" {
        InModuleScope monkeyhtml -Parameters @{
            MockInput = $script:mockInput
            MockTemplate = $script:mockTemplate
        } {
            param($MockInput, $MockTemplate)
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

            $scriptContent = $result.SelectNodes("//script")[0].InnerText
            $scriptContent | Should-NotMatchString "good"
            $scriptContent | Should-NotMatchString "manual"
        }
    }

    It "Creates correct chart structure" {
        InModuleScope monkeyhtml -Parameters @{
            MockInput = $script:mockInput
            MockTemplate = $script:mockTemplate
        } {
            param($MockInput, $MockTemplate)
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

            $div = $result.SelectNodes("//div[@class='chart chart-lg d-flex justify-content-center']")
            $div | Should-NotBeNull
            $div.GetAttribute("id") | Should-Be "monkey_chart_123"
        }
    }

    It "Handles missing template gracefully" {
        InModuleScope monkeyhtml -Parameters @{
            MockInput = $script:mockInput
            MockTemplate = $script:mockTemplate
        } {
            param($MockInput, $MockTemplate)
            $result = New-FindingBySeverityChart -InputObject $mockInput
            $result | Should-NotBeNull
        }
    }

    It "Reports a warning when chart creation fails" {
        InModuleScope monkeyhtml -Parameters @{
            MockInput = $script:mockInput
            MockTemplate = $script:mockTemplate
        } {
            param($MockInput, $MockTemplate)
            Mock Get-PolarAreaChartOption { return $null }
            Mock Write-Warning { }

            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate
            Should-Invoke Write-Warning -Times 1 -ParameterFilter {
                $Message -match 'Unable to create Severity chart'
            }
        }
    }

    It "Sets correct card title and icon" {
        InModuleScope monkeyhtml -Parameters @{
            MockInput = $script:mockInput
            MockTemplate = $script:mockTemplate
        } {
            param($MockInput, $MockTemplate)
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

            $titleElement = $result.SelectNodes("//*[contains(@class, 'card-title')]")
            $titleElement.InnerText | Should-MatchString "Findings By severity"
            $iconElement = $result.SelectNodes("//i[@class='bi bi-pie-chart me-2']")
            $iconElement | Should-NotBeNull
        }
    }
    It "Handles empty input data gracefully" {
        InModuleScope monkeyhtml -Parameters @{
            MockInput = $script:mockInput
            MockTemplate = $script:mockTemplate
        } {
            param($MockInput, $MockTemplate)
            Mock Write-Warning { }
            $emptyInput = @()
            $result = New-FindingBySeverityChart -InputObject $emptyInput -Template $mockTemplate
            Should-Invoke Write-Warning -Times 1 -ParameterFilter {
                $Message -match 'Unable to create Severity chart'
            }
        }
    }
}
