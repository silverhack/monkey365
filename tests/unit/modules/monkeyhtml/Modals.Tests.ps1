Set-StrictMode -Version Latest

Describe 'MonkeyHTML specialized modals' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'creates an error modal with the error icon and requested identity' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $modal = New-HtmlErrorModal -Id error1 -Title 'Monkey365 error' -Size large -Template $template

            $modal.id | Should-Be 'error1'
            $modal.SelectSingleNode('.//h5').InnerText | Should-Be 'Monkey365 error'
            $modal.SelectSingleNode('.//i').class | Should-Be 'bi bi-cloud-drizzle'
            $modal.SelectSingleNode('.//div[contains(@class,"modal-dialog")]').class | Should-MatchString 'modal-lg'
        }
    }

    It 'serializes raw objects into a formatted code block' {
        InModuleScope monkeyhtml {
            Mock Get-Random { 77 }
            [xml]$template = '<html></html>'
            $modal = New-HtmlRawObjectModal -Data ([ordered]@{ name = 'alpha'; enabled = $true }) `
                -Format json -Id raw1 -Template $template
            $code = $modal.SelectSingleNode('.//pre/code')

            $modal.id | Should-Be 'raw1'
            $modal.SelectSingleNode('.//h5').InnerText | Should-Be 'Raw Data'
            $code.id | Should-Be 'MonkeyRawDataObject_77'
            $code.class | Should-Be 'monkey-raw-data json'
            ($code.InnerText | ConvertFrom-Json).name | Should-Be 'alpha'
            ($code.InnerText | ConvertFrom-Json).enabled | Should-BeTrue
        }
    }

    It 'generates an identity when a raw modal id is omitted' {
        InModuleScope monkeyhtml {
            Mock Get-Random { 91 }
            [xml]$template = '<html></html>'
            $modal = New-HtmlRawObjectModal -Data 'value' -Format text -Template $template

            $modal.id | Should-Be 'MonkeyRawDataModal91'
            $modal.SelectSingleNode('.//code').class | Should-Be 'monkey-raw-data text'
        }
    }

    It 'collects standard and finding-specific modals' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            Mock New-HtmlErrorModal { ([xml]'<div id="error"></div>').DocumentElement }
            Mock New-HtmlAboutAuthorModal { ([xml]'<div id="author"></div>').DocumentElement }
            Mock New-HtmlAboutTool { ([xml]'<div id="tool"></div>').DocumentElement }
            Mock New-HtmlRawObjectModal {
                ([xml]('<div id="{0}"></div>' -f $Id)).DocumentElement
            }
            $report = @(
                [pscustomobject]@{
                    level = 'high'
                    displayName = 'Finding'
                    output = [pscustomobject]@{
                        html = [pscustomobject]@{
                            extendedData = @(
                                [ordered]@{ id = 'raw-finding'; format = 'json'; rawData = @{ value = 1 } }
                            )
                        }
                    }
                }
                foreach ($level in @('good', 'manual')) {
                    [pscustomobject]@{
                        level = $level
                        displayName = "Excluded $level finding"
                        output = [pscustomobject]@{
                            html = [pscustomobject]@{
                                extendedData = @(
                                    [ordered]@{
                                        id = "raw-$level"
                                        format = 'json'
                                        rawData = @{ value = 2 }
                                    }
                                )
                            }
                        }
                    }
                }
            )

            $modals = @(Get-AllModalHtmlObject -Report @($report) -Template $template)
            $modals | Should-BeCollection -Count 4
            @($modals | ForEach-Object id) | Should-ContainCollection 'raw-finding'
            Should-Invoke New-HtmlRawObjectModal -Times 1 -ParameterFilter {
                $Id -eq 'raw-finding' -and $Format -eq 'json'
            }
        }
    }
}
