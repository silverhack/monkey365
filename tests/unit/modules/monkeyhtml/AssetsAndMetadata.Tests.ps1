Set-StrictMode -Version Latest

Describe 'MonkeyHTML assets and metadata rendering' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    Context 'Icon resolution' {
        It 'maps known Fabric icon names and provides a fallback' {
            InModuleScope monkeyhtml {
                Get-FabricIcon -InputObject 'Microsoft Entra ID' | Should-Be 'ms-Icon ms-Icon--AADLogo'
                Get-FabricIcon -InputObject 'Not a service' | Should-Be 'bi bi-box-arrow-down-right nav-icon'
            }
        }

        It 'resolves known and fallback SVG icons in local mode' {
            InModuleScope monkeyhtml {
                $script:mode = 'local'
                $script:LocalPath = 'C:/report-assets'

                Get-SvgIcon -InputObject Users | Should-MatchString 'C:/report-assets/assets/.+Users\.svg$'
                Get-SvgIcon -InputObject 'Unknown Service' |
                    Should-MatchString 'C:/report-assets/assets/.+All-Resources\.svg$'
            }
        }

        It 'resolves assets against a local CDN repository' {
            InModuleScope monkeyhtml {
                $script:mode = 'localcdn'
                $script:Repository = 'https://assets.example.test/base'

                Get-SvgIcon -InputObject 'Microsoft 365' |
                    Should-Be 'https://assets.example.test/base/assets/inc-officeicons/64x64/office-365.svg'
            }
        }

        It 'converts branch-hosted SVG assets through jsDelivr' {
            InModuleScope monkeyhtml {
                $script:mode = 'cdn_branch'
                $script:Repository = 'https://github.com/u/assets'
                $script:Branch = 'develop'
                Mock Convert-UrlToJsDelivr { [uri]'https://cdn.example.test/icon.svg' }

                (Get-SvgIcon -InputObject Users).AbsoluteUri | Should-Be 'https://cdn.example.test/icon.svg'
                Should-Invoke Convert-UrlToJsDelivr -Times 1 -ParameterFilter {
                    $Url -match 'github\.com/u/assets/assets/' -and $Branch -eq 'develop'
                }
            }
        }

        It 'warns when raw local SVG content is missing' {
            InModuleScope monkeyhtml {
                $script:mode = 'local'
                $script:LocalPath = 'Z:/path-that-does-not-exist'
                Mock Write-Warning { }

                Get-SvgIcon -InputObject Users -Raw | Should-BeNull
                Should-Invoke Write-Warning -Times 1
            }
        }
    }

    Context 'Get-JSHelper' {
        It 'creates local helper tags with attributes and text' {
            InModuleScope monkeyhtml {
                $script:mode = 'local'
                $script:LocalPath = '/assets'
                $script:Config = [pscustomobject]@{
                    head = [pscustomobject]@{
                        helpers = @(
                            [pscustomobject]@{
                                tagName = 'script'
                                properties = [pscustomobject]@{ src = 'js/app.js'; defer = 'defer' }
                                text = 'ready'
                            }
                        )
                    }
                }
                [xml]$template = '<html></html>'

                $helpers = @(Get-JSHelper -Template $template)
                $helpers | Should-BeCollection -Count 1
                $helpers[0].Name | Should-Be 'script'
                $helpers[0].src | Should-Be '/assets/js/app.js'
                $helpers[0].defer | Should-Be 'defer'
                $helpers[0].InnerText | Should-Be 'ready'
            }
        }

        It 'creates local-CDN helper URLs from the repository' {
            InModuleScope monkeyhtml {
                $script:mode = 'localcdn'
                $script:Repository = 'https://assets.example.test'
                $script:Config = [pscustomobject]@{
                    head = [pscustomobject]@{
                        helpers = @([pscustomobject]@{
                            tagName = 'link'
                            properties = [pscustomobject]@{
                                href = 'css/site.css'
                                rel = 'stylesheet'
                                integrity = 'sha384-test'
                                crossorigin = 'anonymous'
                            }
                        })
                    }
                }
                [xml]$template = '<html></html>'

                $helper = @(Get-JSHelper -Template $template)[0]
                $helper.href | Should-Be 'https://assets.example.test/css/site.css'
                $helper.rel | Should-Be 'stylesheet'
                $helper.integrity | Should-Be 'sha384-test'
                $helper.crossorigin | Should-Be 'anonymous'
            }
        }

        It 'converts branch helper URLs through jsDelivr' {
            InModuleScope monkeyhtml {
                $script:mode = 'cdn_branch'
                $script:Repository = 'https://github.com/u/assets'
                $script:Branch = 'main'
                $script:Config = [pscustomobject]@{
                    head = [pscustomobject]@{
                        helpers = @([pscustomobject]@{
                            tagName = 'script'
                            properties = [pscustomobject]@{ src = 'js/app.js' }
                        })
                    }
                }
                Mock Convert-UrlToJsDelivr { [uri]'https://cdn.example.test/app.js' }
                [xml]$template = '<html></html>'

                $helper = @(Get-JSHelper -Template $template)[0]
                $helper.src | Should-Be 'https://cdn.example.test/app.js'
                Should-Invoke Convert-UrlToJsDelivr -Times 1 -ParameterFilter { $Branch -eq 'main' }
            }
        }
    }

    Context 'Finding card metadata' {
        It 'renders Markdown content as escaped HTML text' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $content = Get-HTMLCardContent -Name Description -Content '**bold**' -Template $template

                $content.SelectSingleNode('./h6').InnerText | Should-Be 'Description'
                $content.SelectSingleNode('./p').InnerText | Should-Be '<strong>bold</strong>'
            }
        }

        It 'renders references as external links' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $content = Get-HTMLCardReference -Name References `
                    -Content @('https://one.example', 'https://two.example') -Template $template
                $links = @($content.SelectNodes('.//a'))

                $links | Should-BeCollection -Count 2
                $links[0].href | Should-Be 'https://one.example'
                $links[0].target | Should-Be '_blank'
                $links[1].InnerText | Should-Be 'https://two.example'
            }
        }

        It 'renders structured and string compliance entries' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $content = Get-HTMLCardCompliance -Name Compliance -Content @(
                    [pscustomobject]@{ name = 'CIS'; version = '2.0'; reference = '1.1' }
                    'Custom'
                ) -Template $template
                $badges = @($content.SelectNodes('.//span'))

                $badges | Should-BeCollection -Count 4
                $badges[0].InnerText | Should-Be 'CIS'
                $badges[1].InnerText | Should-Be '2.0'
                $badges[2].InnerText | Should-Be '1.1'
                $badges[3].InnerText | Should-Be 'Custom'
            }
        }

        It 'renders failed finding identity, severity, status, compliance, and violation count' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $finding = [pscustomobject]@{
                    idSuffix = 'rule-1'
                    level = 'high'
                    statusCode = 'fail'
                    compliance = @('CIS')
                }
                $finding | Add-Member ScriptMethod affectedResourcesCount { 3 }

                $content = Get-HTMLFindingCardInfo -FindingObject $finding -Template $template
                $content.SelectSingleNode('.//input').value | Should-Be 'rule-1'
                $content.SelectSingleNode('.//span[contains(@class,"badge-danger")][text()="high"]') |
                    Should-NotBeNull
                $content.SelectSingleNode('.//span[contains(@class,"badge-danger")][text()="fail"]') |
                    Should-NotBeNull
                $content.SelectSingleNode('.//h4').InnerText | Should-Be '3'
            }
        }

        It 'omits violation count for passing findings' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $finding = [pscustomobject]@{
                    idSuffix = 'rule-2'
                    level = 'good'
                    statusCode = 'pass'
                    compliance = @()
                }
                $finding | Add-Member ScriptMethod affectedResourcesCount { 0 }

                $content = Get-HTMLFindingCardInfo -FindingObject $finding -Template $template
                $content.InnerText | Should-NotMatchString 'Rule Violations'
                $content.SelectSingleNode('.//span[contains(@class,"badge-success")][text()="pass"]') |
                    Should-NotBeNull
            }
        }
    }
}
