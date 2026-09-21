Set-StrictMode -Version Latest

Describe 'MonkeyHTML layout and navigation' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'builds a sidebar with grouped services and resource links' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $script:mode = 'local'
            $script:LocalPath = 'C:/assets'
            Mock Get-SvgIcon {
                if ($Raw) {
                    return ([xml]'<svg><path d="M0 0" /></svg>')
                }
                return 'C:/assets/service.svg'
            }

            $sidebar = New-SideBar -InputObject @(
                [pscustomobject]@{ serviceName = 'Microsoft 365'; serviceType = 'Exchange Online' }
                [pscustomobject]@{ serviceName = 'Microsoft 365'; serviceType = 'SharePoint Online' }
            ) -Template $template

            $sidebar.id | Should-Be 'sidebar'
            $sidebar.SelectSingleNode('.//span[text()="Microsoft 365"]') | Should-NotBeNull
            $sidebar.SelectSingleNode('.//a[@href="javascript:show(''exchange-online'')"]') | Should-NotBeNull
            $sidebar.SelectSingleNode('.//a[@href="javascript:show(''execution-info'')"]') | Should-NotBeNull
            $sidebar.SelectSingleNode('.//a[@href="https://github.com/silverhack/monkey365/issues"]') |
                Should-NotBeNull
        }
    }

    It 'builds the navigation bar from execution identity data' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $script:ExecutionInfo = [pscustomobject]@{
                displayName = 'Ada Lovelace'
                userpic = 'data:image/png;base64,avatar'
            }
            Mock Get-HTMLNavBarGitHubInfo {
                $link = $Template.CreateElement('a')
                $link.SetAttribute('id', 'github-info')
                return $link
            }

            $navbar = New-HTMLNavBar -Template $template

            $navbar.LocalName | Should-Be 'nav'
            $navbar.SelectSingleNode('.//span[@id="username"]').InnerText | Should-Be 'Ada Lovelace'
            $navbar.SelectSingleNode('.//img[@alt="Ada Lovelace"]').src |
                Should-Be 'data:image/png;base64,avatar'
            $navbar.SelectSingleNode('.//a[@id="github-info"]') | Should-NotBeNull
            $navbar.SelectSingleNode('.//input[@placeholder="Search"]') | Should-NotBeNull
        }
    }

    It 'builds metadata and configured local asset elements in the document head' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $script:mode = 'local'
            $script:LocalPath = 'C:/report-assets'
            $script:Config = [pscustomobject]@{
                head = [pscustomobject]@{
                    styles = @(
                        [pscustomobject]@{
                            tagName = 'link'
                            properties = [pscustomobject]@{
                                rel = 'stylesheet'
                                href = 'css/site.css'
                                integrity = 'ignored-locally'
                                crossorigin = 'anonymous'
                            }
                            text = $null
                        }
                    )
                    scripts = @(
                        [pscustomobject]@{
                            tagName = 'script'
                            properties = [pscustomobject]@{ src = 'js/app.js'; defer = 'defer' }
                            text = 'window.monkeyReady = true;'
                        }
                    )
                    helpers = @(
                        [pscustomobject]@{ tagName = 'script'; properties = [pscustomobject]@{ src = 'js/helper.js' } }
                    )
                }
            }

            $head = Get-HtmlHeader -Template $template

            $head.LocalName | Should-Be 'head'
            $head.SelectSingleNode('./meta[@charset="utf-8"]') | Should-NotBeNull
            $head.SelectSingleNode('./link[@href="C:/report-assets/css/site.css"]').rel |
                Should-Be 'stylesheet'
            $head.SelectSingleNode('./link').HasAttribute('integrity') | Should-BeFalse
            $head.SelectSingleNode('./script[@src="C:/report-assets/js/app.js"]').InnerText |
                Should-Be 'window.monkeyReady = true;'
            $head.SelectSingleNode('./script[@src="C:/report-assets/js/helper.js"]') | Should-BeNull
        }
    }
}
