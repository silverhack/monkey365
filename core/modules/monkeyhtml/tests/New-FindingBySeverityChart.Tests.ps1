Set-StrictMode -Version Latest
Import-Module Pester

Describe "New-FindingBySeverityChart" {
    BeforeAll {
        $module = (Get-Item $PSScriptRoot).Parent
        Import-Module $module.FullName -Force

        # Mock input data
        $global:mockInput = @(
            @{ level = "High" },
            @{ level = "Medium" },
            @{ level = "Low" },
            @{ level = "Good" },
            @{ level = "Manual" },
            @{ level = "High" }
        )

        # Mock template
        [xml]$script:mockTemplate = "<html></html>"

        # Mock dependent functions
        Mock Get-ColorFromLevel { return "danger" } -ModuleName monkeyhtml
        Mock Get-DonutChartOption { return "var donutOptions = {};" } -ModuleName monkeyhtml
        Mock Get-PolarAreaChartOption { return "var polarOptions = {};" } -ModuleName monkeyhtml
    }

    BeforeEach {
        # Reset mocks before each test
        Mock Get-Random { return 123 }
    }

    It "Creates a polar area chart by default" {
        InModuleScope monkeyhtml {
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

            Should -Invoke Get-PolarAreaChartOption -Times 1
            $result.GetAttribute("class") | Should -Match "h-100"
        }
    }
    <#
    It "Creates a donut chart when specified" {
        InModuleScope monkeyhtml {
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate -Donut

            Should -Invoke Get-DonutChartOption -Times 1
            $result.GetAttribute("class") | Should -Match "h-100"
        }
    }

    It "Filters out 'good' and 'manual' levels" {
        InModuleScope monkeyhtml {
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

            $scriptContent = $result.SelectNodes("//script")[0].InnerText
            $scriptContent | Should -Not -Match "good"
            $scriptContent | Should -Not -Match "manual"
        }
    }

    It "Creates correct chart structure" {
        InModuleScope monkeyhtml {
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

            $div = $result.SelectNodes("//div[@class='chart chart-lg d-flex justify-content-center']")
            $div | Should -Not -BeNullOrEmpty
            $div.GetAttribute("id") | Should -Be "monkey_chart_123"
        }
    }

    It "Handles missing template gracefully" {
        InModuleScope monkeyhtml {
            $result = New-FindingBySeverityChart -InputObject $mockInput
            $result | Should -Not -BeNullOrEmpty
        }
    }

    It "Reports error when chart creation fails" {
        InModuleScope monkeyhtml {
            Mock Get-PolarAreaChartOption { return $null }

            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate
            $Global:Error[0].ToString() | Should -Match "Unable to create Severity chart"
        }
    }

    It "Sets correct card title and icon" {
        InModuleScope monkeyhtml {
            $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

            $titleElement = $result.SelectNodes("//*[contains(@class, 'card-title')]")
            $titleElement.InnerText | Should -Match "Findings By severity"
            $iconElement = $result.SelectNodes("//i[@class='bi bi-pie-chart me-2']")
            $iconElement | Should -Not -BeNullOrEmpty
        }
    }
    #>
}
It "Creates a donut chart when specified" {
    InModuleScope monkeyhtml {
        $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate -Donut

        Should -Invoke Get-DonutChartOption -Times 1
        $result.GetAttribute("class") | Should -Match "h-100"
    }
}

It "Filters out 'good' and 'manual' levels" {
    InModuleScope monkeyhtml {
        $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

        $scriptContent = $result.SelectNodes("//script")[0].InnerText
        $scriptContent | Should -Not -Match "good"
        $scriptContent | Should -Not -Match "manual"
    }
}

It "Creates correct chart structure" {
    InModuleScope monkeyhtml {
        $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate

        $div = $result.SelectNodes("//div[@class='chart chart-lg d-flex justify-content-center']")
        $div | Should -Not -BeNullOrEmpty
        $div.GetAttribute("id") | Should -Be "monkey_chart_123"
    }
}

It "Handles missing template gracefully" {
    InModuleScope monkeyhtml {
        $result = New-FindingBySeverityChart -InputObject $mockInput
        $result | Should -Not -BeNullOrEmpty
    }
}

It "Reports error when chart creation fails" {
    InModuleScope monkeyhtml {
        Mock Get-PolarAreaChartOption { return $null }

        $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate
        $Global:Error[0].ToString() | Should -Match "Unable to create Severity chart"
    }
}

It "Sets correct card title and icon" {
    InModuleScope monkeyhtml {
        Mock New-HtmlContainerCard {
            param($CardTitle, $Icon)
            $CardTitle | Should -Be "Findings By severity"
            $Icon | Should -Be "bi bi-pie-chart me-2"
        }

        $result = New-FindingBySeverityChart -InputObject $mockInput -Template $mockTemplate
    }
}

It "Handles empty input data gracefully" {
    InModuleScope monkeyhtml {
        $emptyInput = @()
        $result = New-FindingBySeverityChart -InputObject $emptyInput -Template $mockTemplate
        $Global:Warning[-1] | Should -Match "Unable to create Severity chart"
    }
}
}