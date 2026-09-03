Set-StrictMode -Version Latest

Describe 'MonkeyHTML summary cards' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    BeforeEach {
        InModuleScope monkeyhtml {
            $script:ExecutionInfo = [pscustomobject]@{
                displayName = 'Ada Lovelace'
                userPrincipalName = 'ada@example.test'
                userpic = 'data:image/png;base64,avatar'
                tenant = [pscustomobject]@{ TenantName = 'Contoso'; tenantId = 'tenant-id' }
                subscription = [pscustomobject]@{ displayName = 'Production Subscription' }
                profile = [ordered]@{
                    Tenant = 'Contoso'
                    Environment = 'AzureCloud'
                }
                roles = @('Reader', 'Security Reader')
            }
            $script:RulesetInfo = [ordered]@{
                Name = 'CIS Microsoft 365'
                Version = '6.0'
            }
        }
    }

    It 'renders provider identity for every supported account type' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'

            $azure = New-AccountInfo -Instance Azure -Template $template
            $microsoft365 = New-AccountInfo -Instance Microsoft365 -Template $template
            $entra = New-AccountInfo -Instance EntraID -Template $template

            $azure.SelectSingleNode('.//span[@id="Provider"]').InnerText | Should-Be 'Microsoft Azure'
            $azure.SelectSingleNode('.//i[@id="Provider"]').GetAttribute('class') |
                Should-Be 'ms-Icon ms-Icon--AzureIcon cloud-monkey-color'
            $azure.SelectSingleNode('.//span[@id="AccountName"]').InnerText |
                Should-Be 'Production Subscription'
            $microsoft365.SelectSingleNode('.//span[@id="Provider"]').InnerText | Should-Be 'Microsoft 365'
            $microsoft365.SelectSingleNode('.//i[@id="Provider"]').GetAttribute('class') |
                Should-Be 'ms-Icon ms-Icon--OfficeLogo cloud-monkey-color'
            $entra.SelectSingleNode('.//span[@id="Provider"]').InnerText | Should-Be 'Microsoft Entra ID'
            $entra.SelectSingleNode('.//i[@id="Provider"]').GetAttribute('class') |
                Should-Be 'ms-Icon ms-Icon--AADLogo cloud-monkey-color'
            $entra.SelectSingleNode('.//span[@id="AccountName"]').InnerText | Should-Be 'Contoso'
        }
    }

    It 'creates the complete finding filter control group' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            Mock Get-Random { 42 }

            $filter = New-HtmlCardFilter -Template $template
            $buttons = @($filter.SelectNodes('./button'))

            $filter.id | Should-Be 'search_42'
            $filter.SelectSingleNode('./input').id | Should-Be 'findingfilter_42'
            $buttons | Should-BeCollection -Count 6
            @($buttons | ForEach-Object { $_.'data-filter-name' }) |
                Should-BeCollection @('all', 'good', 'info', 'low', 'warning', 'danger')
        }
    }

    It 'renders the user profile and assigned roles' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'

            $card = New-HtmlUserProfileCard -Template $template

            $card.SelectSingleNode('.//img').alt | Should-Be 'Ada Lovelace'
            $card.SelectSingleNode('.//h4[@class="mt-3 mb-0"]').InnerText | Should-Be 'Ada Lovelace'
            $card.SelectSingleNode('.//span[@class="username"]').InnerText | Should-Be 'ada@example.test'
            @($card.SelectNodes('.//span[@class="badge bg-primary"]')) | Should-BeCollection -Count 2
            $card.InnerText | Should-MatchString 'Security Reader'
        }
    }

    It 'renders ruleset execution details' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'

            $card = New-HtmlExecutionInfoCard -Template $template

            $card.InnerText | Should-MatchString 'Ruleset details'
            $card.InnerText | Should-MatchString 'CIS Microsoft 365'
            $card.InnerText | Should-MatchString '6.0'
        }
    }

    It 'combines profile and ruleset cards into scan details' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'

            $details = New-HtmlScanDetailsCard -Template $template

            $details.id | Should-Be 'execution-info'
            @($details.SelectNodes('./div[contains(@class,"col-md-6")]')) |
                Should-BeCollection -Count 2
            $details.InnerText | Should-MatchString 'Ada Lovelace'
            $details.InnerText | Should-MatchString 'Ruleset details'
        }
    }
}
