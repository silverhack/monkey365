Set-StrictMode -Version Latest

Describe 'MonkeyHTML module orchestration' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'initializes report state from an in-memory configuration' {
        InModuleScope monkeyhtml -Parameters @{ WorkingDirectory = $TestDrive } {
            param($WorkingDirectory)
            $config = [pscustomobject]@{ head = [pscustomobject]@{} }
            $executionInfo = [pscustomobject]@{
                tenant = [pscustomobject]@{ tenantId = 'tenant-id'; TenantName = 'Contoso' }
            }

            $result = Initialize-MonkeyHtml -Report @('finding') -Config $config `
                -AssetsPath $WorkingDirectory -ExecutionInfo $executionInfo -Rules @('rule') `
                -RulesetInfo ([ordered]@{ Name = 'CIS' }) -Instance Microsoft365 `
                -OutDir $WorkingDirectory

            $result | Should-BeTrue
            $script:mode | Should-Be 'config'
            $script:Config | Should-BeSame $config
            $script:LocalPath | Should-Be ([System.IO.DirectoryInfo]$WorkingDirectory).FullName
            $script:ExecutionInfo | Should-BeSame $executionInfo
        }
    }

    It 'loads repository configuration for branch mode' {
        InModuleScope monkeyhtml -Parameters @{ WorkingDirectory = $TestDrive } {
            param($WorkingDirectory)
            Mock Convert-UrlToJsDelivr { [uri]'https://cdn.example.test/assets/config.json' }
            Mock Invoke-WebRequest {
                [pscustomobject]@{
                    StatusCode = [System.Net.HttpStatusCode]::OK
                    Content = '{"head":{"helpers":[]}}'
                }
            }
            $executionInfo = [pscustomobject]@{ tenant = [pscustomobject]@{ tenantId = 'tenant-id' } }

            $result = Initialize-MonkeyHtml -Report @('finding') `
                -Repository 'https://github.com/example/assets' -Branch develop `
                -ExecutionInfo $executionInfo -Rules @('rule') -RulesetInfo @{} `
                -OutDir $WorkingDirectory

            $result | Should-BeTrue
            $script:mode | Should-Be 'cdn_branch'
            $script:Branch | Should-Be 'develop'
            $script:Config.head.helpers | Should-BeCollection -Count 0
            Should-Invoke Convert-UrlToJsDelivr -Times 1 -Exactly -ParameterFilter { $Branch -eq 'develop' }
            Should-Invoke Invoke-WebRequest -Times 1 -Exactly
        }
    }

    It 'renders repository stars and release version without network access' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $script:webRequestCall = 0
            Mock Invoke-WebRequest {
                $script:webRequestCall++
                if ($script:webRequestCall -eq 1) {
                    return [pscustomobject]@{ Content = '{"stargazers_count":365}' }
                }
                return [pscustomobject]@{ Content = '{"tag_name":"v1.2.3"}' }
            }

            $info = Get-HTMLNavBarGitHubInfo -Url 'https://github.com/example/project' -Template $template

            $info.href | Should-Be 'https://github.com/example/project'
            $info.SelectSingleNode('.//span[@id="GitHub"]').InnerText | Should-Be 'v1.2.3'
            $info.SelectSingleNode('.//span[@id="Stars"]').InnerText | Should-Be '365'
            Should-Invoke Invoke-WebRequest -Times 2 -Exactly
        }
    }

    It 'builds the Monkey365 information modal' {
        InModuleScope monkeyhtml {
            $script:mode = 'local'
            $script:LocalPath = 'C:/report-assets'

            $modal = New-HtmlAboutTool

            $modal.id | Should-Be 'aboutMonkeyModal'
            $modal.SelectSingleNode('.//h5').InnerText | Should-Be 'About Monkey365'
            $modal.SelectSingleNode('.//img[@alt="monkey365"]').src |
                Should-Be 'C:/report-assets/assets/inc-monkey/logo/MonkeyLogo.png'
            @($modal.SelectNodes('.//ul[@class="list-inline"]/li')) | Should-BeCollection -Count 3
        }
    }

    It 'builds the author information modal and social links' {
        InModuleScope monkeyhtml {
            $modal = New-HtmlAboutAuthorModal

            $modal.id | Should-Be 'aboutAuthorModal'
            $modal.SelectSingleNode('.//h5').InnerText | Should-Be 'About Author'
            $modal.InnerText | Should-MatchString 'Juan Garrido'
            @($modal.SelectNodes('.//ul[@class="list-inline"]/li')) | Should-BeCollection -Count 4
            $modal.SelectSingleNode('.//a[@href="https://github.com/silverhack"]') | Should-NotBeNull
        }
    }

    It 'assembles and writes a complete report through its collaborators' {
        InModuleScope monkeyhtml -Parameters @{ WorkingDirectory = $TestDrive } {
            param($WorkingDirectory)
            $executionInfo = [pscustomobject]@{
                tenant = [pscustomobject]@{ tenantId = '11111111-2222-3333-4444-555555555555' }
            }
            $config = [pscustomobject]@{ head = [pscustomobject]@{} }
            Mock Initialize-MonkeyHtml {
                [xml]$script:Template = '<html lang="en"></html>'
                $script:Report = $Report
                $script:ExecutionInfo = $ExecutionInfo
                $script:Rules = $Rules
                $script:RulesetInfo = $RulesetInfo
                $script:OutDir = $OutDir
                return $true
            }
            Mock Get-HtmlHeader { $script:Template.CreateElement('head') }
            Mock New-SideBar {
                $element = $script:Template.CreateElement('div')
                [void]$element.SetAttribute('id', 'sidebar')
                return $element
            }
            Mock New-HTMLNavBar { $script:Template.CreateElement('nav') }
            Mock Get-HtmlContainerCard { @() }
            Mock Get-AllModalHtmlObject { @() }
            Mock New-AccountInfo { $script:Template.CreateElement('section') }
            Mock New-HtmlScanDetailsCard { $null }
            Mock New-HtmlMainDashboard { $null }
            Mock Get-SvgIcon { 'C:/assets/monkey.svg' }
            Mock Get-JSHelper { @() }

            New-HtmlReport -Report @([pscustomobject]@{ serviceType = 'Exchange Online' }) `
                -Config $config -AssetsPath $WorkingDirectory -ExecutionInfo $executionInfo `
                -Rules @([pscustomobject]@{ serviceType = 'Exchange Online' }) `
                -RulesetInfo ([ordered]@{ Name = 'CIS' }) -Instance Microsoft365 `
                -OutDir $WorkingDirectory

            $reports = @(Get-ChildItem -LiteralPath $WorkingDirectory -Filter 'monkey365_local_*.html')
            $reports | Should-BeCollection -Count 1
            Get-Content -Raw -LiteralPath $reports[0].FullName | Should-MatchString '<body'
            Should-Invoke Initialize-MonkeyHtml -Times 1 -Exactly
            Should-Invoke New-SideBar -Times 1 -Exactly
            Should-Invoke New-HTMLNavBar -Times 1 -Exactly
        }
    }
}
