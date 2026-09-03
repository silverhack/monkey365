Set-StrictMode -Version Latest

Describe 'MonkeyHTML dashboard and finding cards' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'summarizes rule and finding counts by service' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            Mock Get-SvgIcon { 'C:/assets/service.svg' }
            $findings = @(
                [pscustomobject]@{ serviceType = 'Exchange Online'; level = 'high' }
                [pscustomobject]@{ serviceType = 'Exchange Online'; level = 'good' }
                [pscustomobject]@{ serviceType = 'SharePoint Online'; level = 'medium' }
            )
            $rules = @(
                [pscustomobject]@{ serviceType = 'Exchange Online' }
                [pscustomobject]@{ serviceType = 'Exchange Online' }
                [pscustomobject]@{ serviceType = 'SharePoint Online' }
            )

            $card = Get-DashboardTable -InputObject $findings -Rules $rules -Template $template
            $rows = @($card.SelectNodes('.//tbody/tr'))

            $rows | Should-BeCollection -Count 2
            @($rows[0].SelectNodes('./td'))[1].InnerText | Should-Be '2'
            @($rows[0].SelectNodes('./td'))[2].InnerText | Should-Be '1'
            $card.SelectSingleNode('.//tfoot/tr/td').colspan | Should-Be '3'
        }
    }

    It 'warns when dashboard rules are unavailable' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            Mock Write-Warning { }

            $result = Get-DashboardTable -InputObject @(
                [pscustomobject]@{ serviceType = 'Exchange Online'; level = 'high' }
            ) -Rules $null -Template $template

            $result | Should-BeNull
            Should-Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
                $Message -eq 'Unable to compile dashboard table. Missing rules'
            }
        }
    }

    It 'assembles chart and table components into the main dashboard' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $script:Rules = @([pscustomobject]@{ serviceType = 'Exchange Online' })
            Mock New-FindingByServiceChart {
                $element = $Template.CreateElement('section')
                [void]$element.SetAttribute('id', 'service-chart')
                return $element
            }
            Mock New-FindingBySeverityChart {
                $element = $Template.CreateElement('section')
                [void]$element.SetAttribute('id', 'severity-chart')
                return $element
            }
            Mock Get-DashboardTable {
                $element = $Template.CreateElement('table')
                [void]$element.SetAttribute('id', 'dashboard-table')
                return $element
            }

            $dashboard = New-HtmlMainDashboard -InputObject @(
                [pscustomobject]@{ serviceType = 'Exchange Online'; level = 'high' }
            ) -HorizontalStackedBar -Donut -Template $template

            $dashboard.id | Should-Be 'monkey-main-dashboard'
            $dashboard.SelectSingleNode('.//section[@id="service-chart"]') | Should-NotBeNull
            $dashboard.SelectSingleNode('.//section[@id="severity-chart"]') | Should-NotBeNull
            $dashboard.SelectSingleNode('.//table[@id="dashboard-table"]') | Should-NotBeNull
            Should-Invoke New-FindingByServiceChart -Times 1 -Exactly -ParameterFilter { $HorizontalStackedBar }
            Should-Invoke New-FindingBySeverityChart -Times 1 -Exactly -ParameterFilter { $Donut }
        }
    }

    It 'groups findings into filterable service containers' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $script:Template = $template
            Mock Get-SvgIcon { 'C:/assets/service.svg' }
            Mock New-FindingCard {
                $element = $Template.CreateElement('article')
                [void]$element.SetAttribute('class', 'finding')
                return $element
            }
            $findings = @(
                [pscustomobject]@{ serviceType = 'Exchange Online'; displayName = 'Finding one' }
                [pscustomobject]@{ serviceType = 'Exchange Online'; displayName = 'Finding two' }
            )

            $containers = @(Get-HtmlContainerCard -InputObject $findings -Template $template)

            $containers | Should-NotBeNull
            $containers[0].id | Should-Be 'exchange-online'
            $containers[0].SelectSingleNode('.//div[contains(@class,"input-group")]') | Should-NotBeNull
            @($containers[0].SelectNodes('.//article[@class="finding"]')) | Should-BeCollection -Count 2
        }
    }

    It 'renders a failed finding with details, guidance, references, and output data' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            Mock New-HtmlTableFromObject {
                $Template.CreateElement('table')
            }
            $finding = [pscustomobject]@{
                idSuffix = 'rule-001'
                displayName = 'Administrative accounts are protected'
                level = 'high'
                statusCode = 'fail'
                compliance = @([pscustomobject]@{ name = 'CIS'; version = '6.0'; reference = '1.1' })
                description = '**Description**'
                rationale = 'Security rationale'
                impact = 'Operational impact'
                remediation = [pscustomobject]@{ text = 'Apply the recommended configuration.' }
                references = @('https://example.test/reference')
                output = [pscustomobject]@{
                    html = [pscustomobject]@{
                        out = @([pscustomobject]@{ Name = 'Administrator'; Enabled = $true })
                        table = 'default'
                        decorate = @('Enabled')
                        extendedData = $null
                        emphasis = @('Name')
                        actions = [pscustomobject]@{
                            showModalButton = 'false'
                            showGoToButton = 'false'
                        }
                    }
                }
            }
            $finding | Add-Member ScriptMethod affectedResourcesCount { 1 }

            $card = New-FindingCard -FindingObject $finding -Template $template

            $card.InnerText | Should-MatchString 'Administrative accounts are protected'
            $card.InnerText | Should-MatchString 'Security rationale'
            $card.InnerText | Should-MatchString 'Operational impact'
            $card.InnerText | Should-MatchString 'Apply the recommended configuration.'
            $card.SelectSingleNode('.//a[@href="https://example.test/reference"]') | Should-NotBeNull
            $card.SelectSingleNode('.//table') | Should-NotBeNull
        }
    }

    It 'renders passing findings without an output tab' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $finding = [pscustomobject]@{
                idSuffix = 'rule-002'
                displayName = 'Passing finding'
                level = 'good'
                statusCode = 'pass'
                compliance = @()
                description = $null
            }
            $finding | Add-Member ScriptMethod affectedResourcesCount { 0 }

            $card = New-FindingCard -FindingObject $finding -Template $template

            $card.InnerText | Should-MatchString 'No description available.'
            $card.SelectSingleNode('.//ul[contains(@class,"nav-tabs")]') | Should-BeNull
            $card.SelectSingleNode('.//div[contains(@class,"monkey-finding-row")]') | Should-NotBeNull
        }
    }
}
